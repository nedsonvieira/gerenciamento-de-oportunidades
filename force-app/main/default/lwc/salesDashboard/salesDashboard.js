import { LightningElement, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ChartJS from '@salesforce/resourceUrl/chartjs';

import getOpportunitiesGroupedByStage from '@salesforce/apex/OpportunityService.getOpportunitiesGroupedByStage';
import getKpiSummary from '@salesforce/apex/OpportunityService.getKpiSummary';

export default class SalesDashboard extends LightningElement {
    chart;
    chartJsInitialized = false;

    @track selectedDays = 90;
    @track isLoading = true;

    dayOptions = [
        { label: 'Últimos 30 dias', value: 30 },
        { label: 'Últimos 60 dias', value: 60 },
        { label: 'Últimos 90 dias', value: 90 }
    ];

    kpi = {
        totalOpps: 0,
        totalAmount: 0,
        uniqueOwners: 0
    };

    @wire(getOpportunitiesGroupedByStage, { lastDays: '$selectedDays' })
    wiredOpportunities(result) {
        if (result.data) {
            this.chartData = result.data;
            this.isLoading = false;
            this.callRenderChat();
        } else if (result.error) {
            console.error('Erro ao buscar dados de oportunidades:', result.error);
        }
    }

    @wire(getKpiSummary, { lastDays: '$selectedDays' })
    wiredKpiSummary(result) {
        if (result.data) {
            this.kpi = result.data;
        } else if (result.error) {
            console.error('Erro ao carregar KPIs:', result.error);
        }
    }

    renderedCallback() {
        if (this.chartJsInitialized) return;
        this.chartJsInitialized = true;

        loadScript(this, ChartJS)
            .then(() => {
                this.chartJsInitialized = true;
                this.isLoading = false;
                this.callRenderChat();
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Erro ao carregar Chart.js:', error);
            });
    }

    callRenderChat() {
        if (this.chartJsInitialized && this.chartData.length) {
            this.renderChart();
        }
    }

    renderChart() {
        if (!this.chartJsInitialized || !this.chartData.length) return;

        const ctx = this.template.querySelector('canvas')?.getContext('2d');
        if (!ctx) return;

        if (this.chart) {
            this.chart.destroy();
        }

        const labels = this.chartData.map(row => row.stage);
        const counts = this.chartData.map(row => row.total);
        const amounts = this.chartData.map(row => row.totalAmount);

        this.chart = new window.Chart(ctx, {
            type: 'scatter',
            data: {
                labels: labels,
                datasets: [{
                    type: 'bar',
                    label: 'Valor Total (R$)',
                    data: amounts,
                    borderColor: 'rgb(255, 0, 55)',
                    backgroundColor: 'rgb(255, 99, 132)'
                },
                {
                    type: 'line',
                    label: 'Quantidade de Oportunidades',
                    data: counts,
                    borderColor: 'rgb(54, 162, 235)'
                }]
            },
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    }

    handlePeriodChange(event) {
        this.selectedDays = parseInt(event.detail.value, 10);
    }

    exportCSV() {
        getOpportunitiesGroupedByStage({ lastDays: this.selectedDays })
            .then(data => {
                if (!data || data.length === 0) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Nenhum dado',
                            message: 'Não há oportunidades para exportar neste período.',
                            variant: 'warning'
                        })
                    );
                    return;
                }

                let csv = 'Fase,Oportunidade,Valor Total (R$)\n';
                data.forEach(row => {
                    const stage = row.stage || '';
                    const amount = row.totalAmount || 0;
                    const total = row.total || 0;

                    csv += `"${stage}",${total},${amount}\n`;
                });

                const url = 'data:text/csv;charset=utf-8,' + encodeURI(csv);

                const link = document.createElement('a');
                link.setAttribute('href', url);
                link.setAttribute('download', `dashboard_opp_${this.selectedDays}dias.csv`);
                link.click();

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Exportação concluída',
                        message: `Arquivo CSV exportado com dados dos últimos ${this.selectedDays} dias.`,
                        variant: 'success'
                    })
                );
            })
            .catch(error => {
                console.error('Erro ao exportar CSV:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Erro na exportação',
                        message: 'Ocorreu um erro ao exportar o arquivo. Verifique o console.',
                        variant: 'error'
                    })
                );
            });
    }
}