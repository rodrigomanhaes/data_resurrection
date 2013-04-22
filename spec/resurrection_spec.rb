# coding: utf-8

require 'spec_helper'
require 'logger'
require 'dbf'
require 'iconv'

describe 'DBF data resurrection' do
  before :all do
    resources_folder = File.expand_path(File.join(File.dirname(__FILE__), 'resources'))
    @empty_dbf_file_path = File.join(resources_folder, 'empty_table.dbf')
    @empty_field_file_path = File.join(resources_folder, 'empty_field.dbf')
    @dbf_file_path = File.join(resources_folder, 'nationality.dbf')
    @dbf_ascii_only_path = File.join(resources_folder,
      'nationality-ascii-only.dbf')
    @dbf_table = ::DBF::Table.new(@dbf_file_path)
  end

  before :each do
    create_test_database
    @data_resurrection = DataResurrection::Resuscitator.new(:dbf, test_database_settings)
  end

  context 'data acquiring' do
    it "gets data from table" do
      result = @data_resurrection.get_data(@dbf_table)
      result.first.should == SAMPLE_FIELDS.first
    end

    it "converts encodings" do
      result = @data_resurrection.get_data(@dbf_table,
        :from => 'WINDOWS-1252', :to => 'UTF-8')
      result[1].should == SAMPLE_FIELDS[1]
    end

    it 'supports multiple encodings for the same table (yes, this kind of freaky thing really exist)' do
      result = @data_resurrection.get_data(@dbf_table, :from => 'WINDOWS-1252', :to => 'UTF-8')
      result[2].should_not == SAMPLE_FIELDS[2]
      result = @data_resurrection.get_data(@dbf_table, :from => ['WINDOWS-1252', 'CP850'], :to => 'UTF-8')
      result[2].should == SAMPLE_FIELDS[2]
    end

    it 'ignores deleted (nil) record' do
      expect {
        @data_resurrection.get_data(@dbf_table, :from => 'WINDOWS-1252', :to => 'UTF-8')
      }.to_not raise_error
    end

    context 'when receiving an Iconv::IllegalSequence' do
      class MyIllegalSequence < Iconv::IllegalSequence
        def initialize
        end
      end

      it 'applies next encoding if exists' do
        @data_resurrection.stub(:get_raw_data).and_return([{'a' => 'b'}])
        Iconv.should_receive(:new).once.with('UTF-8', 'WINDOWS-1252').and_return(iconv = stub)
        iconv.stub(:iconv).and_raise(MyIllegalSequence)
        Iconv.should_receive(:new).once.with('UTF-8', 'CP860').and_return(
          stub(:iconv => 'a'))
        @data_resurrection.get_data(@dbf_table, :from => ['WINDOWS-1252', 'CP860'], :to => 'UTF-8')
      end

      it 're-raises exception if there are no more encodings' do
        @data_resurrection.stub(:get_raw_data).and_return([{'a' => 'b'}])
        Iconv.should_receive(:new).once.with('UTF-8', 'WINDOWS-1252').and_return(iconv = stub)
        iconv.stub(:iconv).and_raise(MyIllegalSequence)
        expect {
          @data_resurrection.get_data(@dbf_table, :from => 'WINDOWS-1252', :to => 'UTF-8')
        }.to raise_error(Iconv::IllegalSequence)
      end
    end

    it 'handles name conflicts between field names and Ruby methods' do
      Kernel.module_eval { def nr; Class; end }
      result = @data_resurrection.get_data(@dbf_table, :from => 'WINDOWS-1252', :to => 'UTF-8')
      (0..2).each {|n| result[n]['nr'].should == SAMPLE_FIELDS[n]['nr'] }
    end

    it 'applies arbitrary character replacement when required' do
      result = @data_resurrection.get_data(@dbf_table, { from: 'WINDOWS-1252', to: 'UTF-8' },
        [], '€' => 'Ñ', 'É' => 'Ò')
      result[1]['ds'].should == 'ESTADOS UNIDOS DA AMÒRICA'
      result[2]['ad_patr'].should == 'MOÑAMBICANO'
    end
  end

  context 'feeding target table' do
    before(:each) do
      @data_resurrection.resurrect(@dbf_file_path, :target => 'nationality',
        :from => ['WINDOWS-1252', 'CP850'], :to => 'UTF-8')
    end

    it 'creates table' do
      expect {
        class Nationality < ActiveRecord::Base
          self.table_name = 'nationality'
        end
      }.to_not raise_error
    end

    it 'copies data' do
      Nationality.count.should == 3
      Nationality.all.each_with_index do |record, i|
        SAMPLE_FIELDS[i].each do |field_name, value|
          f = record.attributes[field_name]
          f.should == value
        end
      end
    end

    it 'creates fields of the same type to original table' do
      obj = Nationality.find_by_nr(6)
      obj.nr.should be_a_kind_of Integer
      obj.cd_nac.should be_a_kind_of Integer
    end

    it 'creates table with target name' do
      @data_resurrection.resurrect(@dbf_file_path, :target => 'nationality2',
        :from => 'WINDOWS-1252', :to => 'UTF-8')
      Class.new(ActiveRecord::Base) { self.table_name = 'nationality2' }.count.should == 3
    end

    it 'does not add an id' do
      @data_resurrection.resurrect(@dbf_file_path, :target => 'without_id',
        :from => 'WINDOWS-1252', :to => 'UTF-8')
      obj = Class.new(ActiveRecord::Base) { self.table_name = 'without_id' }.first
      obj.id.should be_nil
    end

    context 'when origin table is empty' do
      it 'creates table anyway' do
        @data_resurrection.resurrect(@empty_dbf_file_path, :target => 'empty_table')
        Class.new(ActiveRecord::Base) { self.table_name = 'empty_table' }.count.should be_zero
      end
    end

    context 'when a field is empty' do
      it 'retrieves an empty content' do
        @data_resurrection.resurrect(@empty_field_file_path, :target => 'empty')
        record = Class.new(ActiveRecord::Base) { self.table_name = 'empty' }.first
        record.a_field.should be_empty
      end
    end
  end

  it 'allows definition of different types for fields' do
    @data_resurrection.resurrect(@dbf_file_path, :target => 'nationality',
      :from => ['WINDOWS-1252', 'CP850'], :to => 'UTF-8',
      :field_types => {:nr => :string })
    Nationality = Class.new(ActiveRecord::Base) { self.table_name = 'nationality' }
    [30, 36, 38].map {|cd_nac|
      Nationality.find_by_cd_nac(cd_nac).nr
    }.should == %w(3 4 6)
  end

  it 'encoding options are optional' do
    expect {
      @data_resurrection.resurrect(@dbf_ascii_only_path, :target => 'nationality')
    }.to_not raise_error
    f = Nationality.all.first
    ASCII_ONLY_FIELDS.values_at('cd_nac', 'nr').should == [f.cd_nac, f.nr]
  end

  context 'handles SQL reserved words appending an underscore' do
    before(:all) { change_reserved_words "NR\nANYTHING" }
    after(:all) { restore_reserved_words }

    before :each do
      @data_resurrection = DataResurrection::Resuscitator.new(:dbf,
        test_database_settings)
    end

    it 'on data retrieving' do
      result = @data_resurrection.get_data(@dbf_table, { :from => 'WINDOWS-1252', :to => 'UTF-8' },
        @data_resurrection.send(:reserved_words))
      [0, 1].each do |n|
        result[n].should have_key 'nr_'
        result[n].should_not have_key 'nr'
      end
    end

    it 'on table creation' do
      @data_resurrection.resurrect(@dbf_file_path, :target => 'nationality', :from => 'WINDOWS-1252', :to => 'UTF-8')
      Class.new(ActiveRecord::Base) { self.table_name = 'nationality' }.new.should respond_to('nr_')
    end
  end
end

SAMPLE_FIELDS = [
  {
    'nr' => 3,
    'ds' => 'ALEMANHA',
    'ad_patr' => 'ALEMAO',
    'cd_nac' => 30
  },
  {
    'nr' => 4,
    'ds' => 'ESTADOS UNIDOS DA AMÉRICA',
    'ad_patr' => 'AMERICANO',
    'cd_nac' => 36
  },
  {
    'nr' => 6,
    'ds' => 'MOÇAMBIQUE',
    'ad_patr' => 'MOÇAMBICANO',
    'cd_nac' => 38
  }
]

ASCII_ONLY_FIELDS = SAMPLE_FIELDS[0]
