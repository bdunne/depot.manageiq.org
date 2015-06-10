class CreateExtension
  def initialize(params, user, github)
    @params = params
    @tags = params[:tag_tokens]
    @user = user
    @github = github
  end

  def process!
    Extension.new(@params).tap do |extension|
      extension.owner = @user

      if extension.valid? and repo_valid?(extension)
        ActiveRecord::Base.transaction do
          extension.save
          create_tags(extension)
        end

        CollectExtensionMetadataWorker.perform_async(extension.id)
      end
    end
  end

  private

  def repo_valid?(extension)
    begin
      result = @github.collaborator?(extension.github_repo, @user.github_account.username)
    rescue ArgumentError, Octokit::Unauthorized
      result = false
    end

    if !result then extension.errors[:github_url] = I18n.t("extension.github_url_format_error") end

    result
  end

  def create_tags(extension)
    (@tags || "").split(",").map(&:strip).each do |tag|
      extension.taggings.add(tag)
    end
  end
end
