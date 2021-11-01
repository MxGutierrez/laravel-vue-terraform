<template>
  <Tutorial :message="message" />
</template>

<script lang="ts">
export default {
  async asyncData({ $axios }) {
    try {
      const { data } = await $axios.get('/test');
      return {
        message: data
      }
    } catch (ex) {
      return {
        message: ex.response.data.message
      }
    }
  }
}
</script>
