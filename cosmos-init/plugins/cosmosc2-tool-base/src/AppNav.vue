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
    <v-navigation-drawer v-model="drawer" app id="cosmos-nav-drawer">
      <v-list>
        <v-list-item two-line>
          <v-list-item-icon>
            <img :src="logo" alt="COSMOS" />
          </v-list-item-icon>
          <v-list-item-content>
            <v-list-item-title class="font-weight-bold">
              COSMOS
            </v-list-item-title>
            <!-- v-list-item-subtitle>Enterprise Edition</v-list-item-subtitle -->
          </v-list-item-content>
        </v-list-item>
        <v-list-item class="my-0">
          <v-list-item-content>
            <div v-for="(tool, name) in adminTools" :key="name">
              <v-btn
                block
                small
                :href="tool.url"
                onclick="singleSpaNavigate(event)"
              >
                Admin
              </v-btn>
            </div>
          </v-list-item-content>
        </v-list-item>
        <v-divider />
        <div v-for="(tool, name) in shownTools" :key="name">
          <v-list-item>
            <v-list-item-icon>
              <a :href="tool.url" onclick="singleSpaNavigate(event)">
                <v-icon>{{ tool.icon }}</v-icon>
              </a>
            </v-list-item-icon>
            <v-list-item-content>
              <a :href="tool.url" onclick="singleSpaNavigate(event)">
                <v-list-item-title>{{ name }}</v-list-item-title>
              </a>
            </v-list-item-content>
            <v-list-item-icon>
              <a :href="tool.url" target="_blank">
                <v-icon>mdi-arrow-top-right-thin-circle-outline</v-icon>
              </a>
            </v-list-item-icon>
          </v-list-item>
        </div>
      </v-list>
    </v-navigation-drawer>
    <v-app-bar app color="tertiary darken-3" id="cosmos-app-toolbar">
      <v-app-bar-nav-icon @click="drawer = !drawer" />
      <span style="width: 100%"><span id="cosmos-menu"></span></span>
      <div class="justify-right mr-2 pt-2"><scope-selector /></div>
      <div class="justify-right"><alert-history /></div>
      <div class="justify-right"><notifications /></div>
      <div class="justify-right"><user-menu /></div>
    </v-app-bar>
  </div>
</template>

<script>
import Api from '../../packages/cosmosc2-tool-common/src/services/api'
import logo from '../public/img/logo.png'
import { registerApplication, start } from 'single-spa'
import ScopeSelector from './components/ScopeSelector.vue'
import AlertHistory from './components/AlertHistory.vue'
import Notifications from './components/Notifications.vue'
import UserMenu from './components/UserMenu.vue'

export default {
  components: {
    ScopeSelector,
    AlertHistory,
    Notifications,
    UserMenu,
  },
  data() {
    return {
      drawer: true,
      appNav: {},
      adminNav: {},
      checked: [],
      logo: logo,
    }
  },
  computed: {
    // a computed getter
    shownTools: function () {
      let result = {}
      for (var key of Object.keys(this.appNav)) {
        if (this.appNav[key].shown && this.appNav[key].category !== 'Admin') {
          result[key] = this.appNav[key]
        }
      }
      return result
    },
    adminTools: function () {
      let result = {}
      for (var key of Object.keys(this.appNav)) {
        if (this.appNav[key].shown && this.appNav[key].category === 'Admin') {
          result[key] = this.appNav[key]
        }
      }
      return result
    },
  },
  created() {
    Api.get('/cosmos-api/tools/all', { params: { scope: 'DEFAULT' } }).then(
      (response) => {
        this.appNav = response.data

        // Register apps and start single-spa
        for (var key of Object.keys(this.appNav)) {
          if (this.appNav[key].shown) {
            let folder_name = this.appNav[key].folder_name
            let name = '@cosmosc2/tool-' + folder_name
            registerApplication({
              name: name,
              app: () => System.import(name),
              activeWhen: ['/tools/' + folder_name],
            })
          }
        }
        start({
          urlRerouteOnly: true,
        })

        // Redirect / to the first tool
        if (window.location.pathname == '/') {
          for (var key of Object.keys(this.shownTools)) {
            if (this.appNav[key].shown) {
              history.replaceState(null, '', this.appNav[key].url)
              break
            }
          }
        }
      }
    )
  },
}
</script>

<style scoped>
.v-list-item--two-line .v-list-item__icon {
  margin: 0px;
}
.v-list >>> .v-label {
  margin-left: 5px;
}
.theme--dark.v-navigation-drawer {
  background-color: var(--v-primary-darken2);
}
.v-list-item__icon {
  /* For some reason the default margin-right is huge */
  margin-right: 15px !important;
}
.v-list-item__title {
  color: white;
}
</style>
