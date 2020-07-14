import Vue from 'vue'

import './styles/quasar.sass'
import '@quasar/extras/material-icons/material-icons.css'
import '@quasar/extras/fontawesome-v5/fontawesome-v5.css'
import { Quasar, Notify } from 'quasar'

Vue.use(Quasar, {
  config: {},
  components: {  },
  directives: { /* not needed if importStrategy is not 'manual' */ },
  plugins: { Notify
  }
 })