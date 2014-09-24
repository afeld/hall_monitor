require 'dotenv'
require 'octokit'

Dotenv.load

class Scraper
  PR_EVENT_TYPES = %w(
    IssueCommentEvent
    PullRequestEvent
    PullRequestReviewCommentEvent
    StatusEvent
  ).to_set.freeze
  # others
  # CommitCommentEvent

  def client
    @client ||= Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
  end

  def pull_requests
    self.client.search_issues('type:pr is:open user:bfl-itp user:cuny-nytech')
  end

  def events
    self.client.organization_public_events('bfl-itp')
  end

  def pr_events
    self.events.select {|event| PR_EVENT_TYPES.include?(event.type) }
  end

  def pr_url(event)
    case event.type
    when 'IssueCommentEvent'
      event.payload.issue.url
    when 'PullRequestEvent', 'PullRequestReviewCommentEvent'
      event.payload.pull_request.url
    else
      raise 'dunno'
    end
  end

  def run
    last_by_pr_url = {}
    self.pr_events.reverse_each do |event|
      begin
        url = pr_url(event)
        last_by_pr_url[url] = event
      rescue => e
        puts event.type
      end
    end

    last_by_pr_url.each do |url, event|
      puts "#{url} #{event.type}"
    end
  end
end
