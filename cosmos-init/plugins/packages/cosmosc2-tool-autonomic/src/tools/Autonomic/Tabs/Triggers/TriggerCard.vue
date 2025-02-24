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
    <v-card outlined>
      <div>
        <v-card-title
          :class="trigger.state ? 'selected-title' : 'available-title'"
        >
          <v-icon class="pr-5">
            {{ trigger.active ? 'mdi-power-plug' : 'mdi-power-plug-off' }}
          </v-icon>
          <v-icon class="pr-5">
            {{ trigger.state ? 'mdi-bell-ring' : 'mdi-bell' }}
          </v-icon>
          <span v-text="trigger.name" />
        </v-card-title>
        <v-card-text>
          <v-simple-table dense>
            <tbody>
              <tr>
                <th class="text-left" width="100">Description</th>
                <td v-text="trigger.description" />
              </tr>
              <tr>
                <th class="text-left" width="100">Active</th>
                <td v-text="trigger.active" />
              </tr>
              <tr>
                <th class="text-left" width="100">State</th>
                <td v-text="trigger.state" />
              </tr>
              <tr>
                <th class="text-left">Eval</th>
                <td v-text="evalDescription" />
              </tr>
            </tbody>
          </v-simple-table>
        </v-card-text>
      </div>

      <v-card-actions>
        <div v-if="trigger.active">
          <v-tooltip top>
            <template v-slot:activator="{ on, attrs }">
              <div v-on="on" v-bind="attrs">
                <v-btn icon data-test="deactivate-icon" @click="deactivate">
                  <v-icon>mdi-power-plug-off</v-icon>
                </v-btn>
              </div>
            </template>
            <span> Deactivate </span>
          </v-tooltip>
        </div>
        <div v-else>
          <v-tooltip top>
            <template v-slot:activator="{ on, attrs }">
              <div v-on="on" v-bind="attrs">
                <v-btn icon data-test="activate-icon" @click="activate">
                  <v-icon>mdi-power-plug</v-icon>
                </v-btn>
              </div>
            </template>
            <span> Activate </span>
          </v-tooltip>
        </div>
        <v-spacer />
        <v-tooltip top>
          <template v-slot:activator="{ on, attrs }">
            <div v-on="on" v-bind="attrs">
              <v-btn icon data-test="delete-icon" @click="deleteHandler">
                <v-icon>mdi-delete</v-icon>
              </v-btn>
            </div>
          </template>
          <span> Delete </span>
        </v-tooltip>
      </v-card-actions>
    </v-card>
  </div>
</template>

<script>
import Api from '@cosmosc2/tool-common/src/services/api'

export default {
  props: {
    trigger: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {}
  },
  created() {},
  computed: {
    leftOperandText: function () {
      return this.trigger.left[this.trigger.left.type]
    },
    rightOperandText: function () {
      return this.trigger.right[this.trigger.right.type]
    },
    evalDescription: function () {
      return `${this.leftOperandText} ${this.trigger.operator} ${this.rightOperandText}`
    },
  },
  watch: {},
  methods: {
    activate: function () {
      Api.post(
        `/cosmos-api/autonomic/${this.trigger.group}/trigger/${this.trigger.name}/activate`,
        {}
      ).then((response) => {
        this.$notify.normal({
          title: 'Activated Trigger',
          body: `Trigger: ${this.trigger.name} has been activated.`,
        })
      })
    },
    deactivate: function () {
      Api.post(
        `/cosmos-api/autonomic/${this.trigger.group}/trigger/${this.trigger.name}/deactivate`,
        {}
      ).then((response) => {
        this.$notify.normal({
          title: 'Deactivated Trigger',
          body: `Trigger: ${this.trigger.name} has been deactivated.`,
        })
      })
    },
    deleteHandler: function () {
      Api.delete(
        `/cosmos-api/autonomic/${this.trigger.group}/trigger/${this.trigger.name}`
      ).then((response) => {
        this.$notify.normal({
          title: 'Trigger Deleted',
          body: `Trigger: ${this.trigger.name} has been deleted.`,
        })
      })
    },
  },
}
</script>

<style scoped>
.selected-title {
  background-color: var(--v-secondary-base);
}
.available-title {
  background-color: var(--v-primary-darken2);
}
</style>
