FactoryGirl.define do
  factory :ml_list_user, class: 'Ml::ListUser' do
    user_id 1
    list_id 1
    is_ban false
    pending false
    is_on_white_list false
    is_moderator false
    is_admin false
  end
end
