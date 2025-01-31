import {
    FtlPlayer
} from "janus-ftl-player";

let player; 

export default {
    mounted() {
        let parent = this;
        let container = this.el;
        let videoLoadingContainer = document.getElementById("video-loading-container");
        let forceMuted = container.dataset.muted;
        let saveVolumeChanges = false;
        let currentlyInUltrawide = false;

        // Handle 21:9 aspect ratio monitors/browers
        let containerParent = container.parentElement;
        // Get browser aspect ratio
        let size = {
            width: window.innerWidth || document.body.clientWidth,
            height: window.innerHeight || document.body.clientHeight
        }
        let currentAspectRatio = size.width / size.height;
        if (currentAspectRatio > 2.3) {
            // We assume this is an ultrawide of some sort
            parent.pushEvent("ultrawide", {enabled: true});
            currentlyInUltrawide = true;
        }

        this.handleEvent("load_video", ({janus_url, channel_id}) => {
            player = new FtlPlayer(container, janus_url, {
                hooks: {
                    janusSlowLink(uplink, lostPackets) {
                        parent.pushEvent("lost_packets", {
                            uplink: uplink,
                            lostPackets: lostPackets
                        });
                        console.debug(`GLIMESH.TV LOST PACKETS uplink=${uplink} lostPackets=${lostPackets}`)
                    }
                }
            }); 
            console.debug(`load_video event for janus_url=${janus_url} channel_id=${channel_id}`)
            player.init(channel_id);

            // Ensure we only save volume changes after the stream has been loaded.
            saveVolumeChanges = true;
        }); 

        if(forceMuted) {
            // If the parent player wants us to be muted, eg: homepage
            // container.volume = 0;
            container.muted = true;
        } else {
            // Otherwise, get the last known volume level.
            let lastVolume = localStorage.getItem("player-volume");
            if (lastVolume && lastVolume >= 0) {
                container.volume = parseFloat(lastVolume);
            }
        }

        container.addEventListener("volumechange", (event) => {
            if (saveVolumeChanges && container.volume >=0) {
                localStorage.setItem("player-volume", container.volume);
            }
        });
     
        container.addEventListener("loadeddata", function() {
            let playPromise = container.play();
            if (playPromise !== undefined) {
                playPromise.then(_ => {
                  // Autoplay started!
                }).catch(error => {
                    console.error(error);
                    container.muted = true;
                    container.play();
                });
              }
        });

        container.addEventListener("waiting", function() {
            videoLoadingContainer.classList.add("loading");
        });
        
        container.addEventListener("abort", function() {
            videoLoadingContainer.classList.add("loading");
        });

        container.addEventListener("playing", function() {
            videoLoadingContainer.classList.remove("loading");
        });

        window.onresize = function() {
            // Get current aspect ratio
            let size = {
                width: window.innerWidth || document.body.clientWidth,
                height: window.innerHeight || document.body.clientHeight
            }
            let currentAspectRatio = size.width / size.height;
            if (currentAspectRatio > 2.3) {
                if (!currentlyInUltrawide) {
                    parent.pushEvent("ultrawide", {enabled: true});
                }
                currentlyInUltrawide = true;
            } else {
                if (currentlyInUltrawide) {
                    parent.pushEvent("ultrawide", {enabled: false});
                }
                currentlyInUltrawide = false;
            }
        }
    },
    destroyed() {
        if(player) {
            player.destroy();
        }
    }
};