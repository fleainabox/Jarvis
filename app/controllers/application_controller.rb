class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :set_timezone

  helper_method :current_user
  helper_method :family
  helper_method :gravatar_for
  helper_method :family_url
  helper_method :is_parent
  helper_method :children
  helper_method :parents

  private

  def current_user
    if session[:user_id]
      if User.find_by_id(session[:user_id]) != nil
        @current_user = User.find_by_id(session[:user_id])
      end
    end
  end

  def is_parent
    redirect_to user_path(current_user), alert: "Not authorized" if current_user.user_type < 20
  end

  def authorize
    redirect_to login_url, alert: "Need to sign in" if !current_user
  end

  def family
    users = Array.new
    if current_user.family
      memberships = FamilyMember.where(family_id: current_user.family.id)
      memberships.each do |membership|
        users << User.find_by_id(membership.user_id)
      end
    else
      users << current_user
    end
    return users
  end

  def children
    users = Array.new
    if current_user.family
      memberships = FamilyMember.where(family_id: current_user.family.id)
      memberships.each do |membership|
        member = User.find_by_id(membership.user_id)
        if member.user_type < 10
          users << member
        end
      end
    end
    return users
  end

  def parents
    users = Array.new
    if current_user.family
      memberships = FamilyMember.where(family_id: current_user.family.id)
      memberships.each do |membership|
        member = User.find_by_id(membership.user_id)
        if member.user_type >= 10
          users << member
        end
      end
    else
      users << current_user
    end
    return users
  end

  def gravatar_for(email)
    id = Digest::MD5::hexdigest email.strip.downcase
    url = 'http://www.gravatar.com/avatar/' + id + '?d=retro'
    return url
  end

  def set_timezone
    if current_user
      Time.zone = current_user.time_zone
    end
  end
end