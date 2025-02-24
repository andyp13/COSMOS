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
  <v-row justify="center">
    <v-dialog
      v-model="isVisible"
      @keydown.esc="isVisible = false"
      width="790px"
    >
      <v-card>
        <v-card-title>{{ header }}</v-card-title>
        <v-card-text>
          Packet Time: {{ packetTime }}
          <br />
          Received Time: {{ receivedTime }}
          <br />
          <v-btn color="primary" class="mt-2" @click="pause">
            {{ buttonLabel }}
          </v-btn>
          <v-textarea class="pa-0 ma-0" v-model="rawData" auto-grow readonly />
        </v-card-text>
      </v-card>
    </v-dialog>
  </v-row>
</template>

<script>
import Updater from './Updater'

export default {
  mixins: [Updater],
  props: {
    type: String,
    visible: Boolean,
    targetName: String,
    packetName: String,
  },
  data() {
    return {
      header: '',
      packetTime: '',
      receivedTime: '',
      rawData: '',
      paused: false,
      buttonLabel: 'Pause',
    }
  },
  computed: {
    isVisible: {
      get: function () {
        return this.visible
      },
      // Reset all the data to defaults
      set: function (bool) {
        this.header = ''
        this.packetTime = ''
        this.receivedTime = ''
        this.rawData = ''
        this.paused = false
        this.buttonLabel = 'Pause'
        this.$emit('display', bool)
      },
    },
  },
  methods: {
    pause() {
      this.paused = !this.paused
      if (this.paused) {
        this.buttonLabel = 'Resume'
      } else {
        this.buttonLabel = 'Pause'
      }
    },
    update() {
      if (!this.isVisible || this.paused) return
      this.header =
        'Raw ' +
        this.type +
        ' Packet: ' +
        this.targetName +
        ' ' +
        this.packetName

      if (this.type === 'Telemetry') {
        this.api
          .get_tlm_values([
            `${this.targetName}__${this.packetName}__PACKET_TIMEFORMATTED__CONVERTED`,
            `${this.targetName}__${this.packetName}__RECEIVED_TIMEFORMATTED__CONVERTED`,
          ])
          .then((values) => {
            this.packetTime = values[0][0]
            this.receivedTime = values[1][0]
          })
        this.api
          .get_tlm_buffer(this.targetName, this.packetName)
          .then((value) => {
            this.rawData =
              'Address   Data                                             Ascii\n' +
              '---------------------------------------------------------------------------\n' +
              this.formatBuffer(value.raw)
          })
      } else {
        // Command
        this.api
          .get_cmd_value(
            this.targetName,
            this.packetName,
            'RECEIVED_TIMEFORMATTED'
          )
          .then((value) => {
            this.packetTime = value
            this.receivedTime = value
          })
        this.api
          .get_cmd_buffer(this.targetName, this.packetName)
          .then((value) => {
            this.rawData =
              'Address   Data                                             Ascii\n' +
              '---------------------------------------------------------------------------\n' +
              this.formatBuffer(value.raw)
          })
      }
    },
    // TODO: Perhaps move this to a utility library
    formatBuffer(buffer) {
      var string = ''
      var index = 0
      var ascii = ''
      buffer.forEach((byte) => {
        if (index % 16 === 0) {
          string += this.numHex(index, 8) + ': '
        }
        string += this.numHex(byte)

        // Create the ASCII representation if printable
        if (byte >= 32 && byte <= 126) {
          ascii += String.fromCharCode(byte)
        } else {
          ascii += ' '
        }

        index++

        if (index % 16 === 0) {
          string += '  ' + ascii + '\n'
          ascii = ''
        } else {
          string += ' '
        }
      })

      // We're done printing all the bytes. Now check to see if we ended in the
      // middle of a line. If so we have to print out the final ASCII if
      // requested.
      if (index % 16 != 0) {
        var existing_length = (index % 16) - 1 + (index % 16) * 2
        // 47 is (16 * 2) + 15 separator spaces
        var filler = ' '.repeat(47 - existing_length)
        var ascii_filler = ' '.repeat(16 - ascii.length)
        string += filler + '  ' + ascii + ascii_filler
      }
      return string
    },
    numHex(num, width = 2) {
      var hex = num.toString(16)
      return '0'.repeat(width - hex.length) + hex
    },
  },
}
</script>
<style scoped>
.theme--dark .v-card__title,
.theme--dark .v-card__subtitle {
  background-color: var(--v-secondary-darken3);
}

.v-textarea >>> textarea {
  margin-top: 10px;
  font-family: 'Courier New', Courier, monospace;
}
</style>
