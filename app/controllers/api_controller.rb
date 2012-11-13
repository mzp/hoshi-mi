class ApiController < ApplicationController

  skip_before_filter :verify_authenticity_token, :only => [:log]

  def beginning_of_hour(t)
    t.change(:min => 0)
  end

  def end_of_hour(t)
    t.change(:min => 59, :sec => 59)
  end

  def log
    # search graph
    service, section, name = params[:service], params[:section], params[:graph]
    graph = Graph.where(:service => service, :section => section, :name => name, :secret => params[:secret]).first
    if graph.nil?
      render :json => {:message => "#{service}/#{section}/#{name} not found"}.to_json
      return
    end

    now = params[:time] ? Time.parse(params[:time]) : Time.now
    # delete today's log
    Log.delete_all(["graph_id = ? and happened_at >= ? and happened_at <= ?", graph.id, beginning_of_hour(now), end_of_hour(now)])

    # add log
    log = Log.new(:happened_at => now, :number => params[:number])
    log.graph = graph
    if log.save
      render :json => {:message => 'ok'}.to_json
    else
      render :json => {:message => 'failed'}.to_json
    end
  end
end
