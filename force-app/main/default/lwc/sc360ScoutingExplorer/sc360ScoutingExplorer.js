import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFilterOptions from '@salesforce/apex/SC360ScoutingExplorerController.getFilterOptions';
import searchProspects from '@salesforce/apex/SC360ScoutingExplorerController.searchProspects';
import promoteToPriority from '@salesforce/apex/SC360ScoutingExplorerController.promoteToPriority';
import addProspectToPipeline from '@salesforce/apex/SC360ScoutingExplorerController.addProspectToPipeline';

const NONE = { label: '— Tous —', value: '' };

export default class Sc360ScoutingExplorer extends NavigationMixin(LightningElement) {
    searchKey = '';
    position = '';
    status = '';
    country = '';
    nationality = '';
    championship = '';
    dataQuality = 'all';

    @track rows = [];
    totalCount = 0;
    loading = false;
    filterOptions;

    draftName = '';
    draftPosition = '';
    draftClub = '';
    showCreateModal = false;

    columns = [
        { label: 'Nom', fieldName: 'name', type: 'text' },
        { label: 'Poste', fieldName: 'position', type: 'text' },
        { label: 'Club', fieldName: 'currentClub', type: 'text' },
        { label: 'Pays', fieldName: 'country', type: 'text' },
        { label: 'Nationalité', fieldName: 'nationality', type: 'text' },
        { label: 'Championnat', fieldName: 'championship', type: 'text' },
        { label: 'Score', fieldName: 'scoutingScore', type: 'number' },
        { label: 'Conf.', fieldName: 'dataConfidence', type: 'number' },
        { label: 'Source', fieldName: 'source', type: 'text' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Ouvrir fiche', name: 'open' },
                    { label: 'Shortlist (Priority)', name: 'shortlist' }
                ],
                menuAlignment: 'right'
            }
        }
    ];

    connectedCallback() {
        this.handleSearch();
    }

    @wire(getFilterOptions)
    wiredFilters({ data, error }) {
        if (data) {
            this.filterOptions = data;
        } else if (error) {
            this.filterOptions = undefined;
        }
    }

    get positionOptions() {
        return this.buildOptions(this.filterOptions?.positions);
    }
    get statusOptions() {
        return this.buildOptions(this.filterOptions?.statuses);
    }
    get countryOptions() {
        return this.buildOptions(this.filterOptions?.countries);
    }
    get nationalityOptions() {
        return this.buildOptions(this.filterOptions?.nationalities);
    }
    get championshipOptions() {
        return this.buildOptions(this.filterOptions?.championships);
    }
    get dataQualityOptions() {
        const raw = this.filterOptions?.dataQualityBuckets;
        if (!raw || !raw.length) {
            return [
                { label: 'Toutes données', value: 'all' },
                { label: 'Confiance >= 70%', value: 'high' },
                { label: 'Confiance < 70%', value: 'low' },
                { label: 'Confiance vide', value: 'empty' }
            ];
        }
        return raw.map((x) => ({ label: x.label, value: x.value }));
    }

    buildOptions(arr) {
        const opts = [NONE];
        if (!arr || !arr.length) {
            return opts;
        }
        arr.forEach((v) => {
            if (v) {
                opts.push({ label: v, value: v });
            }
        });
        return opts;
    }

    get mapMarkers() {
        const markers = [];
        this.rows.forEach((r) => {
            if (r.geoLatitude != null && r.geoLongitude != null) {
                markers.push({
                    location: {
                        Latitude: Number(r.geoLatitude),
                        Longitude: Number(r.geoLongitude)
                    },
                    title: r.name || 'Prospect',
                    description: [r.currentClub, r.country].filter(Boolean).join(' · ')
                });
            }
        });
        return markers;
    }

    get hasMap() {
        return this.mapMarkers.length > 0;
    }

    handleSearchKey(e) {
        this.searchKey = e.target.value;
    }

    handleChange(event) {
        const f = event.target.dataset.field;
        if (f) {
            this[f] = event.detail.value;
        }
    }

    async handleSearch() {
        this.loading = true;
        try {
            const res = await searchProspects({
                searchKey: this.searchKey,
                position: this.position,
                status: this.status,
                country: this.country,
                nationality: this.nationality,
                championship: this.championship,
                dataQuality: this.dataQuality,
                rowLimit: 75
            });
            this.rows = res.rows || [];
            this.totalCount = res.totalCount || 0;
        } catch (e) {
            this.toast('Erreur recherche', this.reduceError(e), 'error');
            this.rows = [];
        } finally {
            this.loading = false;
        }
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        if (action.name === 'open' && row.id) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: row.id, objectApiName: 'Prospect__c', actionName: 'view' }
            });
        } else if (action.name === 'shortlist' && row.id) {
            this.runShortlist(row.id);
        }
    }

    async runShortlist(prospectId) {
        try {
            await promoteToPriority({ prospectId });
            this.toast('Shortlist', 'Prospect passé en Priority.', 'success');
            await this.handleSearch();
        } catch (e) {
            this.toast('Erreur', this.reduceError(e), 'error');
        }
    }

    openNewProspect() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: { objectApiName: 'Prospect__c', actionName: 'new' }
        });
    }

    openCreateModal() {
        this.draftName = this.searchKey || '';
        this.draftPosition = this.position || '';
        this.draftClub = '';
        this.showCreateModal = true;
    }

    closeCreateModal() {
        this.showCreateModal = false;
    }

    stopProp(e) {
        e.stopPropagation();
    }

    handleDraftChange(e) {
        const f = e.target.dataset.field;
        if (f === 'name') {
            this.draftName = e.target.value;
        }
        if (f === 'position') {
            this.draftPosition = e.target.value;
        }
        if (f === 'club') {
            this.draftClub = e.target.value;
        }
    }

    async saveDraftProspect() {
        if (!this.draftName || !this.draftName.trim()) {
            this.toast('Validation', 'Nom obligatoire.', 'warning');
            return;
        }
        try {
            const id = await addProspectToPipeline({
                name: this.draftName.trim(),
                position: this.draftPosition,
                currentClub: this.draftClub,
                country: this.country,
                nationality: this.nationality,
                championship: this.championship,
                status: 'Under Review'
            });
            this.toast('Créé', 'Prospect ajouté au pipeline.', 'success');
            this.showCreateModal = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: id, objectApiName: 'Prospect__c', actionName: 'view' }
            });
            await this.handleSearch();
        } catch (e) {
            this.toast('Erreur', this.reduceError(e), 'error');
        }
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    reduceError(e) {
        if (e.body && e.body.message) {
            return e.body.message;
        }
        if (e.message) {
            return e.message;
        }
        return 'Erreur inconnue.';
    }
}
