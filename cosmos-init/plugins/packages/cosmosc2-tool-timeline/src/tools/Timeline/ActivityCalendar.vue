<!--
# Copyright 2022 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# This program may also be used under the terms of a commercial or
# enterprise edition license of COSMOS if purchased from the
# copyright holder
-->

<template>
  <div>
    <v-sheet height="64">
      <v-toolbar>
        <v-menu bottom right>
          <template v-slot:activator="{ on, attrs }">
            <v-btn data-test="changeType" outlined v-bind="attrs" v-on="on">
              <span>{{ typeToLabel[type] }}</span>
              <v-icon right> mdi-menu-down </v-icon>
            </v-btn>
          </template>
          <v-list>
            <v-list-item data-test="typeDay" @click="type = 'day'">
              <v-list-item-title>Day</v-list-item-title>
            </v-list-item>
            <v-list-item data-test="type4day" @click="type = '4day'">
              <v-list-item-title>4 Days</v-list-item-title>
            </v-list-item>
            <v-list-item data-test="typeWeek" @click="type = 'week'">
              <v-list-item-title>Week</v-list-item-title>
            </v-list-item>
          </v-list>
        </v-menu>
        <v-btn fab text small data-test="prev" @click="prev">
          <v-icon small> mdi-chevron-left </v-icon>
        </v-btn>
        <v-btn fab text small data-test="next" @click="next">
          <v-icon small> mdi-chevron-right </v-icon>
        </v-btn>
        <v-toolbar-title v-if="$refs.calendar">
          {{ $refs.calendar.title }}
        </v-toolbar-title>
        <v-spacer />
        <v-toolbar-title v-text="title" />
        <v-spacer />
        <v-menu :close-on-content-click="false" :nudge-width="200" offset-x>
          <template v-slot:activator="{ on, attrs }">
            <v-btn data-test="searchDate" icon v-bind="attrs" v-on="on">
              <v-icon>mdi-magnify</v-icon>
            </v-btn>
          </template>
          <v-card>
            <v-list>
              <v-list-item>
                <v-text-field
                  v-model="searchDate"
                  type="date"
                  label="Search Date"
                  :rules="[rules.required, rules.calendar]"
                  data-test="searchDate"
                />
                <v-btn
                  color="success"
                  class="ml-2"
                  @click="updateCalendarDate()"
                >
                  Go
                </v-btn>
              </v-list-item>
            </v-list>
          </v-card>
        </v-menu>
        <activity-create-dialog
          v-on="$listeners"
          v-model="showCreateDialog"
          :timeline="activities[0].name"
          :display-time-in-utc="displayTimeInUtc"
        />
        <v-btn outlined class="mr-4" data-test="today" @click="setToday">
          Today
        </v-btn>
      </v-toolbar>
    </v-sheet>
    <!-- The calendar view -->
    <v-sheet height="900" class="mt-1">
      <v-calendar
        v-model="focus"
        ref="calendar"
        color="primary"
        :events="calendarData"
        :event-color="getEventColor"
        :type="type"
        @click:event="showActivity"
        @click:more="viewDay"
        @click:date="viewDay"
      >
        <!--
        <template v-slot:event="{ event }">
          <span class="font-weight-bold mr-1">{{ event.name }}</span>
          <span>{{ event.start | time(displayTimeInUtc) }}</span>
        </template>
        -->
        <template v-slot:day-body="{ date, week }">
          <div
            class="v-current-time"
            :class="{ first: date === week[0].date }"
            :style="{ top: nowY }"
          ></div>
        </template>
      </v-calendar>
      <v-menu
        v-model="selectedOpen"
        data-test="openSelectedActivity"
        :close-on-content-click="false"
        :activator="selectedElement"
        offset-x
      >
        <v-card flat min-width="400px" v-if="selectedOpen">
          <v-system-bar>
            <v-spacer />
            <span>
              Activity: {{ selectedActivity.name }}/{{ selectedActivity.start }}
            </span>
            <v-spacer />
          </v-system-bar>
          <v-card-text>
            <v-simple-table dense>
              <tbody>
                <tr>
                  <th class="text-left" width="100">Fulfilled</th>
                  <td v-text="selectedActivity.fulfillment" />
                </tr>
                <tr>
                  <th class="text-left" width="100">Start Time</th>
                  <td>
                    {{ selectedActivity.start | dateTime(displayTimeInUtc) }}
                  </td>
                </tr>
                <tr>
                  <th class="text-left">Stop Time</th>
                  <td>
                    {{ selectedActivity.stop | dateTime(displayTimeInUtc) }}
                  </td>
                </tr>
                <tr>
                  <th class="text-left" v-text="selectedActivity.kind" />
                  <td v-text="selectedActivity.data[selectedActivity.kind]" />
                </tr>
                <tr>
                  <th class="text-left">Events</th>
                  <td v-text="selectedActivity.events.length" />
                </tr>
              </tbody>
            </v-simple-table>
          </v-card-text>
          <v-card-actions>
            <v-tooltip top>
              <template v-slot:activator="{ on, attrs }">
                <div v-on="on" v-bind="attrs">
                  <v-icon
                    class="ma-2"
                    data-test="viewActivityIcon"
                    @click="eventDialog"
                  >
                    mdi-eye
                  </v-icon>
                </div>
              </template>
              <span> View Activity </span>
            </v-tooltip>
            <div v-if="!selectedActivity.fulfillment">
              <v-tooltip top>
                <template v-slot:activator="{ on, attrs }">
                  <div v-on="on" v-bind="attrs">
                    <v-icon
                      class="ma-2"
                      data-test="updateActivityIcon"
                      @click="updateDialog"
                    >
                      mdi-pencil
                    </v-icon>
                  </div>
                </template>
                <span> Update Activity </span>
              </v-tooltip>
            </div>
            <v-spacer />
            <v-tooltip top>
              <template v-slot:activator="{ on, attrs }">
                <div v-on="on" v-bind="attrs">
                  <v-icon
                    class="ma-2"
                    data-test="deleteActivityIcon"
                    @click="deleteDialog"
                  >
                    mdi-delete
                  </v-icon>
                </div>
              </template>
              <span> Delete Activity </span>
            </v-tooltip>
          </v-card-actions>
        </v-card>
      </v-menu>
    </v-sheet>
    <!-- Note we're using v-if here so it gets re-created each time and refreshes the list -->
    <activity-event-dialog
      v-if="showActivityDialog"
      v-model="showActivityDialog"
      :activity="selectedActivity"
      :display-time-in-utc="displayTimeInUtc"
    />
    <activity-update-dialog
      v-if="showUpdateDialog"
      v-model="showUpdateDialog"
      :activity="selectedActivity"
      :display-time-in-utc="displayTimeInUtc"
      @close="activityCallback"
    />
  </div>
</template>

<script>
import { isValid, parse, format, getTime } from 'date-fns'
import ActivityCreateDialog from '@/tools/Timeline/ActivityCreateDialog'
import ActivityEventDialog from '@/tools/Timeline/ActivityEventDialog'
import ActivityUpdateDialog from '@/tools/Timeline/ActivityUpdateDialog'
import TimeFilters from './util/timeFilters.js'

export default {
  components: {
    ActivityCreateDialog,
    ActivityEventDialog,
    ActivityUpdateDialog,
  },
  mixins: [TimeFilters],
  props: {
    activities: {
      type: Array,
      required: true,
    },
    displayTimeInUtc: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      rules: {
        required: (value) => !!value || 'Required',
        calendar: (value) => {
          try {
            return (
              isValid(parse(value, 'yyyy-MM-dd', new Date())) ||
              'Invalid date (YYYY-MM-DD)'
            )
          } catch (e) {
            return 'Invalid date (YYYY-MM-DD)'
          }
        },
      },
      searchDate: format(new Date(), 'yyyy-MM-dd'),
      focus: '',
      ready: false,
      type: '4day',
      typeToLabel: {
        week: 'Week',
        '4day': '4 Days',
        day: 'Day',
      },
      selectedActivity: null,
      selectedElement: null,
      showCreateDialog: false,
      showActivityDialog: false,
      showUpdateDialog: false,
      selectedOpen: false,
    }
  },
  computed: {
    title: function () {
      if (!this.activities) return 'Timeline'
      return this.activities.map((timeline) => timeline.name).join(', ')
    },
    singleTimeline: function () {
      if (!this.activities) return false
      return this.activities.length === 1
    },
    calendarData: function () {
      if (!this.activities) return []
      return this.activities.flatMap((timeline, timelineIndex) =>
        timeline.activities.map((activity, activityIndex) => {
          return {
            name: activity.name,
            start: new Date(activity.start * 1000),
            end: new Date(activity.stop * 1000),
            color: timeline.color,
            category: activity.name,
            timed: true,
            key: {
              timelineIndex,
              activityIndex,
            },
          }
        })
      )
    },
    cal: function () {
      return this.ready ? this.$refs.calendar : null
    },
    nowY: function () {
      return this.cal ? this.cal.timeToY(this.cal.times.now) + 'px' : '-10px'
    },
    show: {
      get() {
        return this.value
      },
      set(value) {
        this.$emit('input', this.value) // input is the default event when using v-model
      },
    },
  },
  mounted() {
    this.ready = true
    this.scrollToTime()
    this.updateTime()
    this.cal.checkChange()
  },
  methods: {
    generateDateTime(activity) {
      if (!activity) return ''
      const date = new Date(activity.start * 1000)
      if (this.displayTimeInUtc) {
        return date.toUTCString()
      } else {
        return date.toLocaleString() // TODO: support other locales besides en-US
      }
    },
    activityCallback(activity_content) {
      this.selectedOpen = false
      this.selectedActivity = activity_content
    },
    viewDay({ date }) {
      this.focus = date
      this.type = 'day'
    },
    getEventColor(activity) {
      return activity.color
    },
    setToday() {
      this.focus = ''
    },
    prev() {
      this.cal.prev()
    },
    next() {
      this.cal.next()
    },
    getCurrentTime() {
      return this.cal
        ? this.cal.times.now.hour * 60 + this.cal.times.now.minute
        : 0
    },
    scrollToTime() {
      const time = this.getCurrentTime()
      const first = Math.max(0, time - (time % 30) - 30)
      this.cal.scrollToTime(first)
    },
    updateTime() {
      setInterval(() => this.cal.updateTimes(), 60 * 1000)
    },
    updateCalendarDate() {
      this.focus = this.searchDate
    },
    showActivity({ nativeEvent, event }) {
      const activity =
        this.activities[event.key.timelineIndex].activities[
          event.key.activityIndex
        ]
      const open = () => {
        this.selectedActivity = activity
        this.selectedElement = nativeEvent.target
        requestAnimationFrame(() =>
          requestAnimationFrame(() => (this.selectedOpen = true))
        )
      }
      if (this.selectedOpen) {
        this.selectedOpen = false
        requestAnimationFrame(() => requestAnimationFrame(() => open()))
      } else {
        open()
      }
      nativeEvent.stopPropagation()
    },

    createActivity() {
      this.showCreateDialog = !this.showCreateDialog
    },
    eventDialog() {
      this.showActivityDialog = !this.showActivityDialog
    },
    updateDialog() {
      this.showUpdateDialog = !this.showUpdateDialog
    },
    deleteDialog() {
      const activityTime = this.generateDateTime(this.selectedActivity)
      this.$dialog
        .confirm(
          `Are you sure you want to remove activity: ${activityTime} (${this.selectedActivity.start}) from timeline: ${this.selectedActivity.name}`,
          {
            okText: 'Delete',
            cancelText: 'Cancel',
          }
        )
        .then((dialog) => {
          return Api.delete(
            `/cosmos-api/timeline/${this.selectedActivity.name}/activity/${this.selectedActivity.start}`
          )
        })
        .then((response) => {
          const alertObject = {
            text: `Deleted activity: ${activityTime} (${this.selectedActivity.start}) from timeline: ${this.selectedActivity.name}`,
            type: 'warning',
          }
          this.$emit('alert', alertObject)
          this.$emit('close')
        })
        .catch((error) => {
          if (error) {
            const alertObject = {
              text: `Failed to delete activity ${this.selectedActivity.start} from timeline: ${this.selectedActivity.name}. Error: ${error}`,
              type: 'error',
            }
            this.$emit('alert', alertObject)
          }
        })
    },
  },
}
</script>

<style scoped lang="scss">
.theme--dark .v-card__title,
.theme--dark .v-card__subtitle {
  background-color: var(--v-secondary-darken3);
}
.v-current-time {
  height: 2px;
  background-color: #ea4335;
  position: absolute;
  left: -1px;
  right: 0;
  pointer-events: none;

  &.first::before {
    content: '';
    position: absolute;
    background-color: #ea4335;
    width: 12px;
    height: 12px;
    border-radius: 50%;
    margin-top: -5px;
    margin-left: -6.5px;
  }
}
</style>
