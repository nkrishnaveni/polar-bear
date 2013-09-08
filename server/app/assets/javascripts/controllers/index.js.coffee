# Copyright 2012 LinkedIn, Inc

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

App = window.App

App.IndexController = Ember.Controller.extend(

  inProgressCount: 0
  aggregateSelectedChecked: false
  clusters: []
  selectedCluster: null
  users: []
  timeZones: []
  selectedUsers: []
  selectedUnit: null
  selectedType: null
  usageData: null
  selectedZone: null
  durationValue: 3
  durationUnit: 'months'
  durationUnits: []
  maxUsersToGraph: 10

  chart_max: null
  chart_min: null

  init: ->
    this.loadClusters()

    detected_zone = jstz.determine().name()

    this.set('selectedZone', detected_zone)

    this.timeZones.push {
      name: detected_zone
    }

    this.durationUnits.push {
      name: 'days'
    }

    this.durationUnits.push {
      name: 'weeks'
    }

    this.durationUnits.push {
      name: 'months'
    }

  loadClusters: ->
    console?.log "Loading clusters"
    this.incrementInProgress()
    $.get('api/clusters',(data,status) =>
      this.decrementInProgress()
      this.set("clusters", data.map (cluster)->
        {name:cluster}
      )
      this.set("selectedCluster",data[0])
    )

  loadUsers: (->
    cluster = this.get("selectedCluster")
    if cluster
      console?.log "Loading users for #{cluster}"
      this.incrementInProgress()
      $.get('api/users',{cluster:cluster},(data,status) =>
        this.decrementInProgress()
        this.set("users", data.map (user)->
          {name:user}
        )
      )
    else
      this.set("users",[])
  ).observes("selectedCluster")

  loadUsage: (->
    # end with current time (in ms)
    date_end = new Date().getTime()

    duration_value = this.get('durationValue')
    duration_unit = this.get('durationUnit')

    end = moment()
    start = moment(end).subtract(duration_unit, duration_value)

    end_time = end.toDate().getTime()
    start_time = start.toDate().getTime()

    selected_unit = this.get("selectedUnit")
    unless selected_unit
      console?.log "Missing unit"
      return

    users = this.get("users")
    unless users
      console?.log "Missing users"
      return

    selected_users = this.get("selectedUsers")
    unless selected_users
      console?.log "Missing selected users"
      return

    selected_cluster = this.get("selectedCluster")
    unless selected_cluster
      console?.log "Missing selected cluster"
      return

    selected_type = this.get("selectedType")
    unless selected_type
      console?.log "Missing type"
      return

    selected_zone = this.get("selectedZone")
    unless selected_type
      console?.log "Missing zone"
      return

    users_to_aggregate = []

    # Aggregate all non-selected users in case user wants to graph them.
    selected_users_map = {}
    _(selected_users).each((user)->selected_users_map[user]=true)
    users.forEach((user) ->
      unless selected_users_map[user.name]
        users_to_aggregate.push user.name          
    )

    console?.log "Loading usage data"

    this.incrementInProgress()
    $.ajax(
      url: "api/usage"
      type: "GET"
      data:
        start: start_time,
        end: end_time,
        unit: selected_unit
        zone: selected_zone
        user: selected_users.join(",")
        users_to_aggregate: users_to_aggregate.join(",")
        cluster: selected_cluster
        type: selected_type
      success: (data) =>
        this.decrementInProgress()
        this.set("usageData",data)
    )
  ).observes("selectedUsers","selectedUnit","selectedType","selectedZone","durationUnit","durationValue")

  exportCSV: ->
    console?.log "Exporting CSV"

    duration_value = this.get('durationValue')
    duration_unit = this.get('durationUnit')

    end = moment()
    start = moment(end).subtract(duration_unit, duration_value)

    end_time = end.toDate().getTime()
    start_time = start.toDate().getTime()

    selected_unit = this.get("selectedUnit")
    unless selected_unit
      console?.log "Missing unit"
      return

    users = this.get("users")
    unless users
      console?.log "Missing users"
      return

    selected_users = this.get("selectedUsers")
    unless selected_users
      console?.log "Missing selected users"
      return

    selected_cluster = this.get("selectedCluster")
    unless selected_cluster
      console?.log "Missing selected cluster"
      return

    selected_type = this.get("selectedType")
    unless selected_type
      console?.log "Missing type"
      return

    selected_zone = this.get("selectedZone")
    unless selected_type
      console?.log "Missing zone"
      return

    params = 
      start: start_time,
      end: end_time,
      unit: selected_unit
      zone: selected_zone
      user: selected_users.join(",")
      cluster: selected_cluster
      type: selected_type

    window.location = "api/table?" + $.param(params)

  incrementInProgress: ->
    count = this.get("inProgressCount")
    count++;
    this.set("inProgressCount",count)

  decrementInProgress: ->
    count = this.get("inProgressCount")
    count--;
    this.set("inProgressCount",count)

  isInProgress: (->    
    result = this.get("inProgressCount") > 0
    result
  ).property("inProgressCount")
);