import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getProspectsCompare from '@salesforce/apex/SC360ProspectCompareController.getProspectsCompare';

export default class Sc360ProspectCompare extends NavigationMixin(LightningElement) {
    prospectAId;
    prospectBId;
    @track rows;
    error;
    loading;

    get canCompare() {
        return this.prospectAId && this.prospectBId && this.prospectAId !== this.prospectBId;
    }

    get hasRows() {
        return Array.isArray(this.rows) && this.rows.length === 2;
    }

    get prospectA() {
        return this.hasRows ? this.rows[0] : null;
    }

    get prospectB() {
        return this.hasRows ? this.rows[1] : null;
    }

    get compareDisabled() {
        return !this.canCompare;
    }

    get metricRows() {
        if (!this.hasRows) {
            return [];
        }
        const [a, b] = this.rows;
        const mk = (label, field) => {
            const va = a[field];
            const vb = b[field];
            const both = va != null && vb != null;
            return {
                label,
                aVal: va,
                bVal: vb,
                hasAVal: va != null,
                hasBVal: vb != null,
                delta: both ? va - vb : null,
                showDelta: both
            };
        };
        return [
            mk('Scouting score', 'scoutingScore'),
            mk('Potential', 'potentialScore'),
            mk('Risk', 'riskScore'),
            mk('Fit', 'fitScore'),
            mk('Data confidence', 'dataConfidence')
        ];
    }

    handleChangeA(event) {
        this.prospectAId = event.detail.recordId || null;
        this.clearResult();
    }

    handleChangeB(event) {
        this.prospectBId = event.detail.recordId || null;
        this.clearResult();
    }

    clearResult() {
        this.rows = undefined;
        this.error = undefined;
    }

    async handleCompare() {
        if (!this.canCompare) {
            return;
        }
        this.loading = true;
        this.error = undefined;
        this.rows = undefined;
        try {
            const data = await getProspectsCompare({
                prospectIds: [this.prospectAId, this.prospectBId]
            });
            this.rows = data;
        } catch (e) {
            this.error = this.reduceError(e);
            this.rows = undefined;
        } finally {
            this.loading = false;
        }
    }

    reduceError(e) {
        if (e.body && e.body.message) {
            return e.body.message;
        }
        if (e.message) {
            return e.message;
        }
        return 'Comparaison indisponible.';
    }

    navigateToProspect(event) {
        const id = event.currentTarget.dataset.id;
        if (!id) {
            return;
        }
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                objectApiName: 'Prospect__c',
                actionName: 'view'
            }
        });
    }
}
