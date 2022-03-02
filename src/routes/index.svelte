<script>
  import CheckAddress from '$lib/components/CheckAddress.svelte';
  import { PAGE_TITLE_EXTENSION } from '$lib/constants';
</script>

<style>
a {
  text-align: center;
}
</style>

<svelte:head>
<title>Home {PAGE_TITLE_EXTENSION}</title>
</svelte:head>

<div class="grid">
 <article>
    <a href="/create">Create</a>
 </article>
</div>

<CheckAddress />