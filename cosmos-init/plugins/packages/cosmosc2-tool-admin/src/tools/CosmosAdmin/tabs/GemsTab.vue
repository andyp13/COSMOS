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
    <v-row no-gutters align="center" class="px-2">
      <v-col>
        <div class="px-2">
          <v-btn
            block
            data-test="gemDownload"
            :disabled="files.length > 0"
            @click="showDownloadDialog = true"
          >
            Download
            <v-icon right dark>mdi-cloud-download</v-icon>
          </v-btn>
        </div>
      </v-col>
      <v-col>
        <div class="px-2">
          <v-btn
            block
            color="primary"
            data-test="gemUpload"
            :disabled="files.length < 1"
            :loading="loadingGem"
            @click="upload()"
          >
            Upload
            <template v-slot:loader>
              <span>Loading...</span>
            </template>
            <v-icon right dark>mdi-cloud-upload</v-icon>
          </v-btn>
        </div>
      </v-col>
      <v-col cols="9">
        <div class="px-4">
          <v-file-input
            multiple
            show-size
            v-model="files"
            ref="fileInput"
            accept=".gem"
            label="Click to select .gem file(s) to add to internal gem server"
          />
        </div>
      </v-col>
    </v-row>
    <v-alert
      dismissible
      v-model="showAlert"
      v-text="alert"
      :type="alertType"
      transition="scale-transition"
    />
    <v-list v-if="Object.keys(processes).length > 0" data-test="processList">
      <div v-for="process in processes" :key="process.name">
        <v-list-item>
          <v-list-item-content>
            <v-list-item-title
              v-text="'Installing: ' + process.detail + ' - ' + process.state"
            />
            <v-list-item-subtitle
              v-text="' Updated At: ' + formatDate(process.updated_at)"
            ></v-list-item-subtitle>
          </v-list-item-content>
          <v-list-item-icon v-if="process.state !== 'Running'">
            <v-tooltip bottom>
              <template v-slot:activator="{ on, attrs }">
                <v-icon @click="showOutput(process)" v-bind="attrs" v-on="on">
                  mdi-eye
                </v-icon>
              </template>
              <span>Show Output</span>
            </v-tooltip>
          </v-list-item-icon>
        </v-list-item>
        <v-divider />
      </div>
    </v-list>
    <v-list data-test="gemList">
      <div v-for="(gem, index) in gems" :key="index">
        <v-list-item>
          <v-list-item-content>
            <v-list-item-title v-text="gem" />
          </v-list-item-content>
          <v-list-item-icon>
            <v-tooltip bottom>
              <template v-slot:activator="{ on, attrs }">
                <v-icon @click="deleteGem(gem)" v-bind="attrs" v-on="on">
                  mdi-delete
                </v-icon>
              </template>
              <span>Delete Gem</span>
            </v-tooltip>
          </v-list-item-icon>
        </v-list-item>
        <v-divider v-if="index < gems.length - 1" :key="index" />
      </div>
    </v-list>
    <download-dialog v-model="showDownloadDialog" />
    <simple-text-dialog
      v-model="showProcessOutput"
      title="Process Output"
      :text="processOutput"
    />
  </div>
</template>

<script>
import { toDate, format } from 'date-fns'
import Api from '@cosmosc2/tool-common/src/services/api'
import DownloadDialog from '@/tools/CosmosAdmin/DownloadDialog'
import SimpleTextDialog from '@cosmosc2/tool-common/src/components/SimpleTextDialog'

export default {
  components: {
    DownloadDialog,
    SimpleTextDialog,
  },
  data() {
    return {
      showDownloadDialog: false,
      showProcessOutput: false,
      processOutput: '',
      files: [],
      loadingGem: false,
      gems: [],
      processes: {},
      alert: '',
      alertType: 'success',
      showAlert: false,
    }
  },
  mounted() {
    this.update()
    this.updateProcesses()
  },
  methods: {
    showOutput: function (process) {
      this.processOutput = process.output
      this.showProcessOutput = true
    },
    update() {
      Api.get('/cosmos-api/gems').then((response) => {
        this.gems = response.data
      })
    },
    updateProcesses: function () {
      Api.get('/cosmos-api/process_status/gem_install').then((response) => {
        this.processes = response.data
        if (Object.keys(this.processes).length > 0) {
          setTimeout(() => {
            this.updateProcesses()
            this.update()
          }, 10000)
        }
      })
    },
    formatDate(nanoSecs) {
      return format(
        toDate(parseInt(nanoSecs) / 1_000_000),
        'yyyy-MM-dd HH:mm:ss.SSS'
      )
    },
    upload: function () {
      this.loadingGem = true
      const promises = this.files.map((file) => {
        const formData = new FormData()
        formData.append('gem', file, file.name)
        return Api.post('/cosmos-api/gems', { data: formData })
      })
      Promise.all(promises)
        .then((responses) => {
          this.alert = `Uploaded ${responses.length} gem${
            responses.length > 1 ? 's' : ''
          }`
          this.alertType = 'success'
          this.showAlert = true
          this.loadingGem = false
          this.files = []
          setTimeout(() => {
            this.showAlert = false
            this.updateProcesses()
          }, 5000)
          this.update()
        })
        .catch((error) => {
          this.loadingPlugin = false
        })
    },
    deleteGem: function (gem) {
      this.$dialog
        .confirm(`Are you sure you want to remove: ${gem}`, {
          okText: 'Delete',
          cancelText: 'Cancel',
        })
        .then(function (dialog) {
          return Api.delete(`/cosmos-api/gems/${gem}`)
        })
        .then((response) => {
          this.alert = `Removed gem ${gem}`
          this.alertType = 'success'
          this.showAlert = true
          setTimeout(() => {
            this.showAlert = false
          }, 5000)
          this.update()
        })
    },
  },
}
</script>
