<template>
    <div class="home">
        <img alt="Vue logo" src="../assets/logo.png">

        <HelloWorld msg="Infinity Pool Administrative Center" />
        <Ministo />
    </div>
</template>

<script lang="ts">
import { Component, Vue } from 'vue-property-decorator'
import HelloWorld from '@/components/HelloWorld.vue'
import Ministo from '@/components/Ministo.vue'

@Component({
    components: {
        HelloWorld,
        Ministo
    }
})

export default class Home extends Vue {}
</script>
