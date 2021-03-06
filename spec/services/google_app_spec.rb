require 'rails_helper'


RSpec.describe GoogleApps, type: :service do

  describe "Add Google Apps account to user" do
    fake(:message_sender) { GorgMessageSender }

    let(:user){FactoryGirl.create(:user, firstname: "John", lastname: "Doe", hruid: "john.doe.2011")}

    before(:each) do
      EmailSourceAccountGenerator.new(user).generate
      GoogleApps.new(user).generate
    end

    it "Create redirection to the google apps address" do
      expect(user.email_redirect_accounts.map(&:redirect)).to include('john.doe@gadz.fr')
    end
    it "create redirection with gapps flag" do
      expect(user.email_redirect_accounts.find_by(redirect: 'john.doe@gadz.fr').type_redir).to eq('googleapps')

    end

    # TODO : switch to real uuid after GrAM2 migration
    it "Request a message sending to the message sender for Google Apps creation" do
      gapps = GoogleApps.new(user, message_sender: message_sender).generate
      gapps_email = user.primary_email.to_s
      message = {
        gram_account_uuid: user.uuid,
        primary_email: gapps_email,
        aliases:  user.email_source_accounts.map(&:to_s)-['john.doe@gadz.org']
      }
      expect(message_sender).to have_received.send_message(message, 'request.googleapps.user.create')
    end

    it "Request a message sending to the message sender for Google Apps update" do
      gapps = GoogleApps.new(user, message_sender: message_sender).update
      gapps_email = user.primary_email.to_s
      message = {
        gram_account_uuid: user.uuid,
        aliases:  user.email_source_accounts.map(&:to_s)-['john.doe@gadz.org']
      }
      expect(message_sender).to have_received.send_message(message, 'request.googleapps.user.update')
    end



  end
end
