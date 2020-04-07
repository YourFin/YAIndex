export class ElmVideo extends HTMLElement {
  constructor() {
    super();
    // Create shadowRoot
    this.attachShadow({mode: 'open'});

    if (!this.hasAttribute('src')) {
      // If it doesn't have an src by the time connected callback comes around,
      // we'll add an error then. Until then, don't bother.
      return;
    }

    const src = this.getAttribute('src');
    this.createVideo(src);
  }

  createVideo(src) {
    if (this.errorElement) {
      this.errorElement.remove();
    }
    const vid = document.createElement('video');
    this.videoElement = vid;

    vid.addEventListener('timeupdate', (e) => timeUpdateListener(this, e));
    vid.addEventListener('volumechange', (e) => volumeUpdateListener(this, e));
    vid.addEventListener('loadedmetadata', (e) => loadedMetadataListener(this, e));

    vid.setAttribute('src', src);
    vid.setAttribute('controls', '');
    vid.setAttribute('preload', 'auto');
    vid.setAttribute('controls', '');

    const noVideo = document.createElement('p');
    noVideo.innerText = 'Could not play video :(';
    vid.appendChild(noVideo);

    this.videoElement = vid;

    if (this.hasAttribute('volume')) {
      this.updateVolume(this.getAttribute('volume'));
    }

    if (this.hasAttribute('current-time')) {
      this.updateTime(this.getAttribute('current-time'));
    }

    // Used by timeUpdateListener to figure out whether to update the time
    this.shouldRunTimeCallback = true;

    // Set by timeUpdateListener to tell updateTime /not/ to touch the
    // underlying video element.
    this.shouldUpdateUnderlyingVideo = true;


    this.shadowRoot.appendChild(vid);
  }

  static get observedAttributes() {
    return ['src', 'volume', 'current-time'];
  }
  attributeChangedCallback(name, oldVal, newVal) {
    if (name === 'src') {
      this.updateSrc(oldVal, newVal);
    } else if (name === 'volume') {
      this.updateVolume(oldVal, newVal);
    } else if (name === 'current-time') {
      this.updateTime(oldVal, newVal);
    }
  }

  updateSrc(oldSrc, newSrc) {
    if (!this.videoElement) {
      this.createVideo(newSrc);
    }
    if (oldSrc !== newSrc) {
      this.videoElement.setAttribute('src', newSrc);
    }
  }

  updateVolume(oldVolume, newVolume) {
    if (!this.videoElement) {
      return;
    }
    if (oldVolume !== newVolume) {
      const floatVol = parseFloat(newVolume);
      if (!isNaN(floatVol)) {
        this.videoElement.volume = floatVol;
      }
    }
  }

  updateTime(oldTime, newTime) {
    if (!this.videoElement) {
      return;
    }
    if (!this.shouldUpdateUnderlyingVideo) {
      this.shouldUpdateUnderlyingVideo = true;
      return;
    }
    if (oldTime !== newTime) {
      const floatTime = parseFloat(newTime);
      if (!isNaN(floatTime)) {
        this.videoElement.currentTime = floatTime;
      }
    }
  }

  connectedCallback() {
    // Make sure this element is actually connected
    if (!this.isConnected) {
      return;
    }

    // Add some error text if we don't have a video element
    if (!this.videoElement && this.hasAttribute('src')) {
      // Create the video if need be.
      // this case is actually quite possible.
      this.createVideo(this.getAttribute('src'));
    } else if (!this.videoElement) {
      const errorEl = document.createElement('p');
      errorEl.innerText = 'No video src given';
      this.errorElement = errorEl;
      this.shadowRoot.appendChild(this.errorElement);
      return;
    }
    // else: we already have a video element and don't need to do shit
  }
}

customElements.define('elm-video', ElmVideo);

function timeUpdateListener(elmVid, _) {
  // Logic to only update the video every 500ms with this
  if (elmVid.shouldRunTimeCallback !== true) {
    return;
  }
  elmVid.shouldRunTimeCallback = false;
  setTimeout(() => elmVid.shouldRunTimeCallback = true, 500);

  // Tell the internal update function in setAttribute to /not/ touch the
  // underlying video.
  elmVid.shouldUpdateUnderlyingVideo = false;
  elmVid.setAttribute('current-time', elmVid.videoElement.currentTime);
  const timeUpdateEvent = new CustomEvent('time-updated', {
    detail: { time: elmVid.videoElement.currentTime }
  });
  elmVid.dispatchEvent(timeUpdateEvent);
}

function volumeUpdateListener(elmVid, _) {
  elmVid.setAttribute('volume', elmVid.videoElement.volume);
  const volumeUpdateEvent = new CustomEvent('volume-updated', {
    detail: { volume: elmVid.videoElement.volume }
  });
  elmVid.dispatchEvent(volumeUpdateEvent);
}

function loadedMetadataListener(elmVid, _) {
  const duration = parseFloat(elmVid.getAttribute('duration'));
  if (!isNaN(duration)) {
    const durationEvent = new CustomEvent('duration-found', {
      detail: { duration: duration }
    });
    elmVid.dispatchEvent(durationEvent);
  }
}
