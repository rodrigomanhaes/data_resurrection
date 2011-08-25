# coding: utf-8

require 'spec_helper'
require 'logger'
require 'dbf'

describe 'DBF data resurrection' do
  before :all do
    @dbf_file_path = File.expand_path(File.join(File.dirname(__FILE__), 'resources', 'nationality.dbf'))
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
  end

  context 'feeding target table' do
    before(:each) do
      ActiveRecord::Migration.verbose = false
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
          f = record.send(field_name)
          f.should == value
        end
      end
    end

    it 'creates fields of the same type to original table' do
      obj = Nationality.find_by_nr(6)
      obj.nr.should be_a_kind_of Integer
      obj.cd_nac.should be_a_kind_of Integer
    end
  end

  context 'handles SQL reserved words appending an underscore' do
    before(:all) { change_reserved_words 'NR' }
    after(:all) { restore_reserved_words }

    before :each do
      @data_resurrection = DataResurrection::Resuscitator.new(:dbf,
        test_database_settings)
    end

    it 'on data retrieving' do
      result = @data_resurrection.get_data(@dbf_table, { :from => 'WINDOWS-1252', :to => 'UTF-8' },
        @data_resurrection.send(:sql_reserved_words))
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

