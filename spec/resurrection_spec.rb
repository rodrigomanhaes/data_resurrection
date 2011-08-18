# coding: utf-8

require 'spec_helper'

describe 'DBF data resurrection' do
  before :all do
    @dbf_file_path = File.expand_path(File.join(File.dirname(__FILE__), 'resources', 'nationality.dbf'))
  end

  before :each do
    create_test_database
    @data_resurrection = DataResurrection::Resuscitator.new(:dbf,
      test_database_settings)
  end

  context 'data acquiring' do
    it "gets data from table" do
      result = @data_resurrection.get_data(@dbf_file_path)
      result.first.should == SAMPLE_FIELDS.first
    end

    it "converts encodings" do
      result = @data_resurrection.get_data(@dbf_file_path, :win1252..:utf8)
      result[1].should == SAMPLE_FIELDS[1]
    end
  end

  context 'feeding target table' do
    before(:each) do
      @data_resurrection.resurrect(@dbf_file_path, :target => 'nationality',
        :encodings => :win1252..:utf8)
    end

    it 'creates table' do
      expect {
        class Nationality < ActiveRecord::Base
          self.table_name = 'nationality'
        end
      }.to_not raise_error
    end

    it 'copies data' do
      Nationality.count.should == 2
      Nationality.all.each_with_index do |record, i|
        SAMPLE_FIELDS[i].each do |field_name, value|
          record.send(field_name).should == value.to_s
        end
      end
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
  }
]

