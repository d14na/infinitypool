<template>
    <div class="pool-summary">
        <h1>Pool Summary</h1>

        <h3>Pool is NOT RUNNING!</h3>

        <h5>{{greeting}}</h5>

        <h5>{{challengeDisplay}}</h5>
    </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator'

@Component({
    data: () => ({
        msg: 'Hello',
        challengeNumber: null
    }),
    computed: {
        // need annotation
        greeting(): string {
            return this.greet() + '!'
        },
        challengeDisplay(): string {
            if (this.challengeNumber) {
                return this.challengeNumber
            } else {
                return 'n/a'
            }
        }
    },
    methods: {
        // need annotation due to `this` in return type
        greet(): string {
            return this.msg + ' miners'
        }
    },
    mounted: async function () {
        /* Set stats url */
        const statsUrl = 'http://localhost:3000/stats'

        /* Fetch data. */
        const response = await fetch(statsUrl)

        /* Parse JSON. */
        const stats = await response.json()

        // console.log('STATS', stats)

        /* Set challenge number. */
        if (stats.challengeNumber) {
            this.challengeNumber = stats.challengeNumber
        }
    }
})

export default class PoolInfo extends Vue {}
</script>

<style scoped>
h3 {
    color: rgba(210, 30, 30, 0.7);
}
</style>
