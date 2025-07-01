import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord } from 'lightning/uiRecordApi';

import getRecentOpportunitiesFiltered from '@salesforce/apex/OpportunityService.getRecentOpportunitiesFiltered';

export default class OpportunityList extends NavigationMixin(LightningElement) {

    @track opportunities = [];
    @track error;
    isModalOpen = false;

    stageFilter = '';
    startDate = null;
    endDate = null;

    wiredResult;

    actions = [
        { label: 'Mostrar Detalhes', name: 'show_details' },
        { label: 'Excluir', name: 'delete' },
    ];

    columns = [
        { label: 'Nome', fieldName: 'Name', type: 'text' },
        { label: 'Fase', fieldName: 'StageName', type: 'text' },
        { label: 'Valor', fieldName: 'Amount', type: 'currency' },
        { label: 'Fechamento', fieldName: 'CloseDate', type: 'date' },
        { label: 'Responsável', fieldName: 'OwnerName', type: 'text' },
        {
            type: 'action',
            typeAttributes: { rowActions: this.actions },
        }
    ];

    stageOptions = [
        { label: 'Todas', value: '' },
        { label: 'Prospecting', value: 'Prospecting' },
        { label: 'Qualification', value: 'Qualification' },
        { label: 'Needs Analysis', value: 'Needs Analysis' },
        { label: 'Value Proposition', value: 'Value Proposition' },
        { label: 'Id. Decision Makers', value: 'Id. Decision Makers' },
        { label: 'Perception Analysis', value: 'Perception Analysis' },
        { label: 'Proposal/Price Quote', value: 'Proposal/Price Quote' },
        { label: 'Negotiation/Review', value: 'Negotiation/Review' },
        { label: 'Closed Won', value: 'Closed Won' },
        { label: 'Closed Lost', value: 'Closed Lost' }
    ];

    @wire(getRecentOpportunitiesFiltered, {
        stageFilter: '$stageFilter',
        startDate: '$startDate',
        endDate: '$endDate'
    })
    wiredOpportunities(result) {
        this.wiredResult = result;
        if (result.data) {
            this.opportunities = result.data.map(opp => ({
                ...opp,
                OwnerName: opp.Owner?.Name
            }));
            this.error = null;
        } else if (result.error) {
            this.error = 'Erro ao carregar oportunidades.';
            this.opportunities = [];
            console.error(result.error);
        }
    }

    handleStageChange(event) {
        this.stageFilter = event.detail.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.detail.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.detail.value;
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            case 'show_details':
                this.showRowDetails(row);
                break;
            default:
        }
    }

    deleteRow(row) {
        deleteRecord(row.Id)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Oportunidade Deletada',
                        message: 'Oportunidade ' + row.Name + ' deletada com sucesso!',
                        variant: 'success'
                    })
                );
                this.refreshList();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erro ao deletar',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    showRowDetails(row) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: row.Id,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }

    handleOpenModal() {
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }

    handleDismiss() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields?.forEach(field => field.reset());
        this.handleCloseModal();
    }


    handleSuccess(event) {
        this.handleCloseModal();

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Oportunidade Criada',
                message: 'Oportunidade ' + event.detail.id + ' criada com sucesso!',
                variant: 'success'
            })
        );
        this.refreshList();
    }

    refreshList() {
        refreshApex(this.wiredResult);
    }
}