<script>
  import { page } from "$app/stores";
  import {
    registeringStatus,
    registeringInProgress,
    user,
  } from "$lib/flow/stores";
  import { PAGE_TITLE_EXTENSION } from "$lib/constants";
  import {
    getEvent,
    toggleActive,
    deleteEvent,
    hasRegisteredInEvent,
    register,
  } from "$lib/flow/actions.js";

  import IntersectionObserver from "svelte-intersection-observer";

  import Loading from "$lib/components/common/Loading.svelte";
  import Countdown from "$lib/components/common/Countdown.svelte";
  import Meta from "$lib/components/common/Meta.svelte";
  import Module from "$lib/components/Module.svelte";

  // import ClaimsTable from '$lib/components/common/table/ClaimsTable.svelte';

  let claimsTableInView;

  const eventCallback = async () => {
    let eventData = await getEvent($page.params.address, $page.params.eventId);
    let hasRegistered = await hasRegisteredInEvent(
      $page.params.address,
      $page.params.eventId,
      $user.addr
    );
    let data = { ...eventData, hasRegistered };
    console.log(data);
    return data;
  };

  let whitelist = eventCallback();

  $: currentUnixTime = +new Date() / 1000;
</script>

<svelte:head>
  <title>FLOAT #{$page.params.eventId} {PAGE_TITLE_EXTENSION}</title>
</svelte:head>

<div class="container">
  {#await whitelist}
    <Loading />
  {:then whitelist}
    <Meta
      title="{whitelist?.name} | FLOAT #{$page.params.eventId}"
      author={whitelist?.host}
      description={whitelist?.description}
      url={$page.url} />

    <article>
      <header>
        <a href={whitelist?.url} target="_blank">
          <h1>{whitelist?.name}</h1>
        </a>
        <p>Unique Id: #{$page.params.eventId}</p>
        <p>
          <small class="muted"
            >Created on {new Date(
              whitelist?.dateCreated * 1000
            ).toLocaleString()}</small>
        </p>
      </header>
      {#if whitelist?.hasRegistered}
        <div class="claimed-badge">✓ You're registered!</div>
      {/if}

      <blockquote>
        <strong><small class="muted">DESCRIPTION</small></strong
        ><br />{whitelist?.description}
      </blockquote>
      <p>
        <span class="emphasis">{whitelist?.totalCount}</span> have registered.
      </p>

      <div class="grid">
        {#each whitelist?.modules as module}
          <Module
            amount={parseInt(module.amount)}
            identifier={module.identifier}
            path={module.path} />
        {/each}
      </div>

      <footer>
        {#if whitelist?.hasRegistered}
          <button class="secondary outline" disabled>
            ✓ You're registered!
          </button>
        {:else if $registeringInProgress}
          <button aria-busy="true" disabled>Registering...</button>
        {:else if $registeringStatus.success}
          <a role="button" class="d-block" href="/account" style="display:block"
            >Registered successfully!
          </a>
        {:else if !$registeringStatus.success && $registeringStatus.error}
          <button class="error" disabled>
            {$registeringStatus.error}
          </button>
        {:else}
          <button
            disabled={$registeringInProgress}
            on:click={() => register(whitelist?.eventId, whitelist?.host)}
            >Register
          </button>
        {/if}
        {#if $user?.addr == whitelist?.host}
          <div class="toggle">
            <button
              class="outline"
              on:click={() => toggleActive(whitelist?.eventId)}>
              {whitelist?.active ? "Pause registering" : "Resume registering"}
            </button>
            <button
              class="outline red"
              on:click={() => deleteEvent(whitelist?.eventId)}>
              Delete this whitelist
            </button>
          </div>
        {/if}
      </footer>
    </article>

    <!-- <article>
      <header>
        <h3>Owned by</h3>
      </header>
      <IntersectionObserver
        once
        element={claimsTableInView}
        let:intersecting
        
      >
      <div bind:this={claimsTableInView}>
        {#if intersecting}
          <ClaimsTable address={whitelist?.host} eventId={whitelist?.eventId} />
        {/if}
      </div>
      </IntersectionObserver>
    </article> -->
  {/await}
</div>

<style>
  .grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .container {
    text-align: center;
  }
  blockquote {
    text-align: left;
  }

  .secondary.outline {
    font-weight: 300;
  }

  p {
    margin-bottom: 0px;
  }

  .muted {
    font-size: 0.7rem;
    opacity: 0.7;
  }

  .toggle {
    margin-top: 15px;
    margin-bottom: 0px;
    position: relative;
    display: flex;
    justify-content: space-around;
    height: auto;
  }

  .toggle button {
    width: 30%;
  }

  .small {
    position: relative;
    width: 125px;
    font-size: 13px;
    padding: 5px;
    left: 50%;
    transform: translateX(-50%);
  }

  .error {
    background-color: red;
    border-color: white;
    color: white;
    opacity: 1;
  }

  .claimed-badge {
    width: 250px;
    margin: 0 auto;
    padding: 0.3rem 0.5rem;
    border: 1px solid var(--green);
    border-radius: 100px;
    color: var(--green);
    font-size: 0.7rem;
  }

  .claims {
    text-align: left;
  }
</style>
