<template>
    <div class="hello">
        <p>
            Let's start mining.

            <button class="btn btn-lg btn-primary" @click="mine">Start Mining</button>
        </p>
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
        },
        // need annotation due to `this` in return type
        mine(): bool {
            console.log('start mining');
            return true
        }
    },
    mounted: async function () {
        console.log('this is Ministo!');
        // /* Set stats url */
        // const statsUrl = 'http://localhost:3000/stats'
        //
        // /* Fetch data. */
        // const response = await fetch(statsUrl)
        //
        // /* Parse JSON. */
        // const stats = await response.json()
        //
        // // console.log('STATS', stats)
        //
        // /* Set challenge number. */
        // if (stats.challengeNumber) {
        //     this.challengeNumber = stats.challengeNumber
        // }
    }
})

export default class Ministo extends Vue {}
</script>

<style scoped>
h3 {
    margin: 40px 0 0;
}
ul {
    list-style-type: none;
    padding: 0;
}
li {
    display: inline-block;
    margin: 0 10px;
}
a {
    color: #42b983;
}
</style>
