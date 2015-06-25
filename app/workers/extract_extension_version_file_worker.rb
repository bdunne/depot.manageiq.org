class ExtractExtensionVersionFileWorker
  include Sidekiq::Worker

  def perform(version_id, path)
    @version = ExtensionVersion.find(version_id)
    @extension = version.extension
    contents = @extension.octokit.contents(@extension.github_repo, ref: @version.version, path: path)
    body = Base64.decode64(contents[:content])

    type = if body["MiqReport"]
      "Report"
    elsif body["MiqPolicySet"]
      "Policy"
    elsif body["MiqAlert"]
      "Alert"
    elsif body["dialog_tabs"]
      "Dialog"
    elsif body["MiqWidget"]
      "Widget"
    else
      "Unknown"
    end

    @version.extension_version_content_items.create(
      name: contents[:name],
      path: contents[:path],
      item_type: type,
      github_url: contents[:html_url]
    )

    # Widgets
    # Reports (type of Widget)
    # Policies
    # Alerts
    # Dialogs
  end
end
