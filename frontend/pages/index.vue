<template>
  <Tutorial :message="message" />
</template>

<script lang="ts">
import { Context } from '@nuxt/types';

export default {
  async asyncData({ $axios } : Context) {
    try {
      const { data } = await $axios.get('/test');
      return {
        message: data
      }
    } catch (ex) {
      console.log('ERROR', ex);
      return {
        message: ex.response.data.message
      }
    }
  }
}
</script>
