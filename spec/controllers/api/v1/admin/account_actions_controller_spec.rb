# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::Admin::AccountActionsController do
  render_views

  let(:role)   { UserRole.find_by(name: 'Moderator') }
  let(:user)   { Fabricate(:user, role: role) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account) { Fabricate(:account) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST #create' do
    context 'with type of disable' do
      before do
        post :create, params: { account_id: account.id, type: 'disable' }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', ''

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'performs action against account' do
        expect(account.reload.user_disabled?).to be true
      end

      it 'logs action' do
        log_item = Admin::ActionLog.last

        expect(log_item).to_not be_nil
        expect(log_item.action).to eq :disable
        expect(log_item.account_id).to eq user.account_id
        expect(log_item.target_id).to eq account.user.id
      end
    end

    context 'with no type' do
      before do
        post :create, params: { account_id: account.id }
      end

      it 'returns http unprocessable entity' do
        expect(response).to have_http_status(422)
      end
    end
  end
end
