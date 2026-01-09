({
	cancel : function(component, event, helper){
		const testValues = event.getParam('value');
		if(testValues == 'Testing Application'){	
			helper.closeaction();
		}
		const testValues2 = event.getParam('createIsuuse');
		if (testValues2 == 'Created Issue'){
			helper.closeaction();	
		}
		const testValues3 = event.getParam('TemplateFound');
		if (testValues3 == 'Close Template Found'){
			helper.closeaction();	
		}
		const testValues4 = event.getParam('closeGlobal');
		if (testValues4 == 'Close global action'){
			helper.closeaction();	
		}
	}
  })