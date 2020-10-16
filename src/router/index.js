import Vue from 'vue'
import VueRouter from 'vue-router'
import store from "../store";

import DefaultLayout from '../layouts/Default.vue'
import SimpleLayout from '../layouts/Simple.vue'
//import UBCLayout from '../layouts/UBC.vue'
import Home from '../views/Home.vue'
//import Predict from '../views/Predict.vue'
//import ModelVisualization from '../views/ModelVisualization.vue'
import SignIn from '../views/SignIn.vue'
import SignUp from '../views/SignUp.vue'
import ForgotPassword from '../views/ForgotPassword.vue'

Vue.use(VueRouter)

const router = new VueRouter({
  routes: [
    {
      path: "/",
      component: DefaultLayout,
      children: [
        {
          path: "/",
          name: "home",
          component: Home,
          meta: { requiresAuth: true, name: 'Home' }
        },
        // {
        //   path: "/p/:code",
        //   name: "predict",
        //   component: Predict,
        //   //props: route => ({ ...route.params, ...route.query }), // converts query strings and params to props
        //   meta: { name: 'predict' }
        // },        
        {
          path: '/about',
          name: 'about',
          component: () => import(/* webpackChunkName: "about" */ '../views/About.vue'),
          meta: { requiresAuth: true, name: 'About' }
        }   
      ]
    },
    {
      path: "/simplelayout",
      component: SimpleLayout,
      children: [
        {
          path: "/auth",
          name: "auth",
          component: SignIn,
          props: route => ({ ...route.params, ...route.query }), // converts query strings and params to props
          meta: { name: 'Auth' }
        },
        {
          path: "/signup",
          name: "signup",
          component: SignUp,
          meta: { name: 'SignUp' }
        },
        {
          path: "/forgotpassword",
          name: "forgotpassword",
          component: ForgotPassword,
          meta: { name: 'ForgotPassword' }
        }
      ]
    }
    // {
    //   path: "/ubclayout",
    //   component: UBCLayout,
    //   children: [
    //     {
    //       path: "/v/:code",
    //       name: "visualize",
    //       component: ModelVisualization,
    //       props: route => ({ ...route.params, ...route.query }), // converts query strings and params to props
    //       meta: { name: 'visualization' }
    //     },
    //   ]
    // },
    
  ]
})

/**
 * Authentication Guard for routes with requiresAuth metadata
 *
 * @param {Object} to - Intended route navigation
 * @param {Object} from - Previous route navigation
 * @param {Object} next - Next route navigation
 * @returns {Object} next - Next route
 */

router.beforeEach(async (to, from, next) => {
  if (to.matched.some(record => record.meta.requiresAuth)) {
    if (!store.getters["profile/isAuthenticated"]) {
      try {
        console.log("dispatch profile/getSession");
        await store.dispatch("profile/getSession");
        next();
      } catch (err) {
        //console.log("router beforeEach Error: " + err);
        next({ name: "auth", query: { redirectTo: to.name } });
      }
    }
  }
  next();
});

export default router;