require 'dotenv'
require 'octokit'

Dotenv.load

class Scraper
  def client
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
  end

  def pull_requests
    self.client.search_issues('type:pr is:open user:bfl-itp user:cuny-nytech')
  end

  def events
    self.client.organization_public_events('bfl-itp')
  end

  def pr_url(event)
    case event.type
    when 'IssueCommentEvent'
      event.payload.issue.url
    when 'PullRequestEvent', 'PullRequestReviewCommentEvent'
      event.payload.pull_request.url
    else
      # TODO handle these?
      # CommitCommentEvent
      # StatusEvent
      nil
    end
  end

  def run
    last_by_pr_url = {}
    self.events.reverse_each do |event|
      url = pr_url(event)
      if url
        last_by_pr_url[url] = event
      end
    end

    last_by_pr_url.each do |url, event|
      puts "#{url} #{event.type}"
    end
  end
end
