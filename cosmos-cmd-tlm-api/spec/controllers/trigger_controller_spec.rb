# encoding: ascii-8bit

# Copyright 2022 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# This program may also be used under the terms of a commercial or
# enterprise edition license of COSMOS if purchased from the
# copyright holder

require 'rails_helper'
require 'cosmos/models/auth_model'
require 'cosmos/models/trigger_model'

RSpec.describe TriggerController, :type => :controller do

  AUTH = 'foobar'.freeze
  GROUP = 'ALPHA'.freeze

  before(:each) do
    mock_redis()
    Cosmos::AuthModel.set(AUTH)
    allow(Cosmos::TriggerGroupModel).to receive(:all).and_return([
      {'name' => GROUP, 'color' => PACKET},
    ])
    allow_any_instance_of(Cosmos::MicroserviceModel).to receive(:create).and_return(nil)
  end

  def generate_trigger_hash
    return {
      'group': GROUP,
      'left': {
        'type': 'item',
        'item': 'POSX',
      },
      'operator': '>',
      'right': {
        'type': 'value',
        'value': 690000,
      }
    }
  end

  describe 'GET index' do
    it 'returns an empty array and status code 200' do
      request.headers['Authorization'] = AUTH
      get :index, params: {'scope'=>'DEFAULT'}
      json = JSON.parse(response.body)
      expect(json).to eql([])
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST then GET index with Triggers' do
    it 'returns an array and status code 200' do
      request.headers['Authorization'] = AUTH
      hash = generate_trigger_hash()
      post :create, params: hash.merge({'scope'=>'DEFAULT'})
      expect(response).to have_http_status(:created)
      trigger = JSON.parse(response.body)
      expect(trigger['name']).not_to be_nil
      get :index, params: {'scope'=>'DEFAULT'}
      json = JSON.parse(response.body)
      expect(json.empty?).to eql(false)
      expect(json.length).to eql(1)
      expect(json[0]['name']).to eql(trigger['name'])
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST create' do
    it 'returns a json hash of name and status code 201' do
      request.headers['Authorization'] = AUTH
      hash = generate_trigger_hash()
      post :create, params: hash.merge({'scope'=>'DEFAULT'})
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['name']).not_to be_nil
    end
  end

  describe 'POST two triggers with the same name on different scopes then GET index' do
    it 'returns an array of one and status code 200' do
      request.headers['Authorization'] = AUTH
      hash = generate_trigger_hash()
      post :create, params: hash.merge({'scope'=>'DEFAULT'})
      expect(response).to have_http_status(:created)
      default_json = JSON.parse(response.body)
      post :create, params: hash.merge({'scope'=>'TEST'})
      expect(response).to have_http_status(:created)
      test_json = JSON.parse(response.body)
      # name should not match
      expect(default_json['name']).not_to eql(test_json['name'])
      # check the value on the index
      get :index, params: {'scope'=>'DEFAULT'}
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.empty?).to eql(false)
      expect(json.length).to eql(1)
      expect(json[0]['name']).to eql(default_json['name'])
    end
  end

  # describe 'PUT update' do
  #   it 'returns a json hash of name and status code 200' do
  #     request.headers['Authorization'] = AUTH
  #     hash = generate_trigger_hash()
  #     post :create, params: hash.merge({'scope'=>'DEFAULT'})
  #     expect(response).to have_http_status(:created)
  #     json = JSON.parse(response.body)
  #     expect(json['name']).not_to be_nil
  #     expect(json['dependents']).not_to be_nil
  #     json['right']['value'] = 23
  #     put :update, params: json.merge({'scope'=>'DEFAULT'})
  #     expect(response).to have_http_status(:ok)
  #     json = JSON.parse(response.body)
  #     expect(json['name']).not_to be_nil
  #     expect(json['right']['value']).to eql(23)
  #   end
  # end

  describe 'POST error' do
    it 'returns a hash and status code 400' do
      request.headers['Authorization'] = AUTH
      post :create, params: {'scope'=>'DEFAULT'}
      json = JSON.parse(response.body)
      expect(json['status']).to eql('error')
      expect(json['message']).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST error bad operand' do
    it 'returns a hash and status code 400' do
      request.headers['Authorization'] = AUTH
      post :create, params: {'scope'=>'DEFAULT', 'left' => 'name'}
      json = JSON.parse(response.body)
      expect(json['status']).to eql('error')
      expect(json['message']).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end

  describe 'DELETE error not found' do
    it 'returns a json hash of name and status code 404' do
      request.headers['Authorization'] = AUTH
      delete :destroy, params: {'scope'=>'DEFAULT', 'name'=>'test'}
      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['status']).to eql('error')
      expect(json['message']).not_to be_nil
    end
  end

  describe 'DELETE' do
    it 'returns a json hash of name and status code 204' do
      allow_any_instance_of(Cosmos::MicroserviceModel).to receive(:undeploy).and_return(nil)
      request.headers['Authorization'] = AUTH
      hash = generate_trigger_hash()
      post :create, params: hash.merge({'scope'=>'DEFAULT'})
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      delete :destroy, params: {'scope'=>'DEFAULT', 'name'=>json['name']}
      expect(response).to have_http_status(:no_content)
      json = JSON.parse(response.body)
      expect(json['name']).to eql('test')
    end
  end

end