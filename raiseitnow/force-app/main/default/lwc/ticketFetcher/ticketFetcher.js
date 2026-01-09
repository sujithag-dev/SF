import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import LOTTIE_ERROR from '@salesforce/resourceUrl/error';
import LOTTIE_WEB from '@salesforce/resourceUrl/lottie';
import LOTTIE_LOADING from '@salesforce/resourceUrl/loading';
import LOTTIE_SUCCESS from '@salesforce/resourceUrl/success';
import runFromLwc from '@salesforce/apex/BulkApiCaller.runFromLwc';



export default class TicketFetcher extends LightningElement {
    @track isLoading = true;
    @track isSuccess = false;
    @track isError = false;

    errorAnim;
    loadingAnim;
    successAnim;
    
    resourceUrls = {
        error: LOTTIE_ERROR,
        loading: LOTTIE_LOADING,
        success: LOTTIE_SUCCESS,
        web: LOTTIE_WEB,  
    };

    renderedCallback() {
        if (this.resourcesLoaded) {return;} 

        this.initializeLottie().catch(() => {
            this.showFallback();
        });
    }

    async initializeLottie() {

        try {
            await loadScript(this, LOTTIE_WEB);

            if (typeof lottie === 'undefined') {
                throw new Error('Lottie not available');
            }

            setTimeout(() => {
                this.loadingAnim = this.setupAnimation('loading', LOTTIE_LOADING, true);
                this.successAnim = this.setupAnimation('success', LOTTIE_SUCCESS, false);
                this.errorAnim = this.setupAnimation('error', LOTTIE_ERROR, false);
                this.resourcesLoaded = true;
            }, 0);

        } catch (error) {
            console.error('Error in Lottie initialization:', error);
            throw error;
        }
    }

    setupAnimation(type, animationData, autoplay) {
        const container = this.template.querySelector(`.lottie-container.${type}`);
        if (!container) {
            console.warn(`Missing container for ${type}`);
            return null;
        }
        container.innerHTML = '';

        return lottie.loadAnimation({
            container,
            renderer: 'svg',
            loop: type === 'loading',
            autoplay,
            path: animationData,
            rendererSettings: {
                preserveAspectRatio: 'xMidYMid slice',
                progressiveLoad: true
            }
        });
    }

    showFallback() {
        const containers = this.template.querySelectorAll('.lottie-container');
        containers.forEach(container => {
            const type = Array.from(container.classList)
                .find(cls => ['loading', 'success', 'error'].includes(cls));

            container.innerHTML = `<div class="fallback">${this.getFallbackContent(type)}</div>`;
        });
    }

    getFallbackContent(type) {
        const fallbacks = {
            loading: '🎟️',
            success: '✅',
            error: '❌'
        };
        return fallbacks[type] || '⚠️';
    }

    playSuccessAnimation() {
        const container = this.template.querySelector('.lottie-container.success');

        if (!container) {
            console.warn('Success container not found');
            return;
        }

       
        container.style.display = 'block';

        
        if (!this.successAnim || this.successAnim.isDestroyed) {
            console.log('Reinitializing success animation...');
            this.successAnim = this.setupAnimation('success', LOTTIE_SUCCESS, false);
            setTimeout(() => {
                this.successAnim?.play();
            }, 50);
        } else {
            this.successAnim.goToAndStop(0, true);
            this.successAnim.play();
        }

        this.successAnim?.addEventListener('complete', () => {
            console.log('✅ Success animation completed');
        });
    }
    playErrorAnimation() {
    const container = this.template.querySelector('.lottie-container.error');
    if (!container) {
        console.warn('❗ Error container not found');
        return;
    }

   
    container.style.display = 'block';

   
    if (!this.errorAnim || this.errorAnim.isDestroyed) {
        console.log('Reinitializing error animation...');
        this.errorAnim = this.setupAnimation('error', LOTTIE_ERROR, false);

       
        setTimeout(() => {
            this.errorAnim?.play();
        }, 50);
    } else {
        this.errorAnim.goToAndStop(0, true);
        this.errorAnim.play();
    }

    this.errorAnim?.addEventListener('complete', () => {
        console.log('❌ Error animation completed');
    });
}

    connectedCallback() {
        runFromLwc()
            .then(() => {
                this.isLoading = false;
                this.isSuccess = true;

                setTimeout(() => {
                    this.playSuccessAnimation();
                    setTimeout(() => this.closeWindow(), 1500);
                }, 100);
            })
            .catch(error => {
                console.error('Ticket fetch error:', error);
                this.isLoading = false;
                this.isError = true;

                setTimeout(() => {
                    this.playErrorAnimation();
                    setTimeout(() => this.closeWindow(), 2500);
                }, 100);
            });
    }

    closeWindow() {
        window.open('/lightning/o/Bug_Tracking__c/list?filterName=All', '_self');
    }

    disconnectedCallback() {
        [this.loadingAnim, this.successAnim, this.errorAnim].forEach(anim => {
            if (anim) anim.destroy();
        });
    }
}