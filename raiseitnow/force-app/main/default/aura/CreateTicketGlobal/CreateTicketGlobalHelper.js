/* global $A */
({
	closeaction : function() {
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
		dismissActionPanel.fire();
	}
})