import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// Lead Fields
import AI_SCORE_FIELD from '@salesforce/schema/Lead.AI_Qualification_Score__c';
import AI_TIER_FIELD from '@salesforce/schema/Lead.AI_Qualification_Tier__c';
import AI_SUMMARY_FIELD from '@salesforce/schema/Lead.AI_Qualification_Summary__c';
import AI_ACTION_FIELD from '@salesforce/schema/Lead.AI_Recommended_Action__c';
import AI_REASON_FIELD from '@salesforce/schema/Lead.AI_Disqualification_Reason__c';
import AI_ANALYZED_FIELD from '@salesforce/schema/Lead.AI_Last_Analyzed__c';
import INVESTOR_TYPE_FIELD from '@salesforce/schema/Lead.Investor_Type__c';
import AUM_RANGE_FIELD from '@salesforce/schema/Lead.AUM_Range__c';
import MEXICO_INTEREST_FIELD from '@salesforce/schema/Lead.Mexico_Market_Interest__c';

const FIELDS = [
    AI_SCORE_FIELD,
    AI_TIER_FIELD,
    AI_SUMMARY_FIELD,
    AI_ACTION_FIELD,
    AI_REASON_FIELD,
    AI_ANALYZED_FIELD,
    INVESTOR_TYPE_FIELD,
    AUM_RANGE_FIELD,
    MEXICO_INTEREST_FIELD
];

export default class BmvAIQualification extends LightningElement {

    @api recordId;

    // Wire to get Lead record data
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    leadRecord;

    // ─── Getters ────────────────────────────────────────

    get aiScore() {
        const score = getFieldValue(this.leadRecord.data, AI_SCORE_FIELD);
        return score != null ? Math.round(score) : null;
    }

    get aiTier() {
        return getFieldValue(this.leadRecord.data, AI_TIER_FIELD) || '';
    }

    get aiSummary() {
        return getFieldValue(this.leadRecord.data, AI_SUMMARY_FIELD) || '';
    }

    get aiAction() {
        return getFieldValue(this.leadRecord.data, AI_ACTION_FIELD) || '';
    }

    get aiReason() {
        return getFieldValue(this.leadRecord.data, AI_REASON_FIELD) || '';
    }

    get lastAnalyzed() {
        return getFieldValue(this.leadRecord.data, AI_ANALYZED_FIELD);
    }

    get investorType() {
        return getFieldValue(this.leadRecord.data, INVESTOR_TYPE_FIELD) || 'Not specified';
    }

    get aumRange() {
        return getFieldValue(this.leadRecord.data, AUM_RANGE_FIELD) || 'Not specified';
    }

    get mexicoInterest() {
        return getFieldValue(this.leadRecord.data, MEXICO_INTEREST_FIELD) || 'Not specified';
    }

    // ─── Tier Checks ────────────────────────────────────

    get hasScore() {
        return this.aiScore != null && this.aiScore > 0;
    }

    get isHot() {
        return this.aiTier && this.aiTier.toLowerCase().includes('hot');
    }

    get isWarm() {
        return this.aiTier && this.aiTier.toLowerCase().includes('warm');
    }

    get isCold() {
        return this.aiTier && this.aiTier.toLowerCase().includes('cold') && 
               !this.aiTier.toLowerCase().includes('disq');
    }

    get isDisqualified() {
        return this.aiTier && this.aiTier.toLowerCase().includes('disqualified');
    }

    get showReason() {
        return this.isDisqualified && 
               this.aiReason && 
               this.aiReason !== 'N/A' && 
               this.aiReason !== '';
    }

    // ─── Score Ring ──────────────────────────────────────

    get scoreDashArray() {
        // Circumference of circle r=50 = 2 * PI * 50 = 314.16
        const circumference = 314.16;
        const score = this.aiScore || 0;
        const filled = (score / 100) * circumference;
        const empty = circumference - filled;
        return `${filled} ${empty}`;
    }

    get scoreBarStyle() {
        const score = this.aiScore || 0;
        let color = '#64748B';
        if (score >= 80) color = '#EF4444';
        else if (score >= 50) color = '#F59E0B';
        else if (score >= 20) color = '#3B82F6';
        else color = '#6B7280';
        return `width: ${score}%; background: ${color}`;
    }

    // ─── Formatted Date ──────────────────────────────────

    get formattedDate() {
        if (!this.lastAnalyzed) return '';
        const date = new Date(this.lastAnalyzed);
        return date.toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
}