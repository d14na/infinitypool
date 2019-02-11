import Vue from 'vue'
import Router from 'vue-router'

import Home from './views/Home.vue'

Vue.use(Router)

// FIXME: We will continue to use a SINGLE name for the
//        webpackChunkName, until the latest ZeroNet Core update
//        has time to be widely adopted, which breaks due to the use
//        of tilde (~) in the code-splitting filename.
//        (updated as of 2019.2.11)

export default new Router({
    routes: [
        {
            path: '/',
            name: 'home',
            component: Home
        }, {
            path: '/about',
            name: 'about',
            component: () => import(/* webpackChunkName: "bundle" */ './views/About.vue')
        }, {
            path: '/pool-info',
            name: 'poolInfo',
            component: () => import(/* webpackChunkName: "bundle" */ './views/PoolInfo.vue')
        }
    ]
})
