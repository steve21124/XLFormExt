#import "XLLinkCell.h"
#import "XLFormBaseCell+Deselect.h"

@implementation XLLinkCell

- (void)configure {
	[super configure];
}

- (void)update {
	[super update];
	self.textLabel.text = self.rowDescriptor.title;
	self.detailTextLabel.text = [self.rowDescriptor.value description];
	if (self.rowDescriptor.action.formBlock || self.rowDescriptor.action.formSelector || self.rowDescriptor.action.formSegueIdentifier || self.rowDescriptor.action.formSegueClass || [self controllerToPresent]) {
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		return;
	} else {
		self.accessoryType = UITableViewCellAccessoryNone;
	}
}

-(void)formDescriptorCellDidSelectedWithFormController:(XLFormViewController *)controller {
	[self deselect:controller];
	if (self.rowDescriptor.action.formBlock) {
		self.rowDescriptor.action.formBlock(self.rowDescriptor);
	} else if (self.rowDescriptor.action.formSelector){
		[controller performFormSelector:self.rowDescriptor.action.formSelector withObject:self.rowDescriptor];
	} else if ([self.rowDescriptor.action.formSegueIdentifier length] != 0){
		[controller performSegueWithIdentifier:self.rowDescriptor.action.formSegueIdentifier sender:self.rowDescriptor];
	} else if (self.rowDescriptor.action.formSegueClass){
		UIViewController * controllerToPresent = [self controllerToPresent];
		NSAssert(controllerToPresent, @"either rowDescriptor.action.viewControllerClass or rowDescriptor.action.viewControllerStoryboardId or rowDescriptor.action.viewControllerNibName must be assigned");
		UIStoryboardSegue * segue = [[self.rowDescriptor.action.formSegueClass alloc] initWithIdentifier:self.rowDescriptor.tag source:controller destination:controllerToPresent];
		[controller prepareForSegue:segue sender:self.rowDescriptor];
		[segue perform];
	} else {
		UIViewController * controllerToPresent = [self controllerToPresent];
		if (controllerToPresent) {
			if ([controllerToPresent conformsToProtocol:@protocol(XLFormRowDescriptorViewController)]){
				((UIViewController<XLFormRowDescriptorViewController> *)controllerToPresent).rowDescriptor = self.rowDescriptor;
			}
			if (controller.navigationController == nil || [controllerToPresent isKindOfClass:[UINavigationController class]] || self.rowDescriptor.action.viewControllerPresentationMode == XLFormPresentationModePresent){
				[controller presentViewController:controllerToPresent animated:YES completion:nil];
			} else {
				// push view controller
				BOOL isRootViewWithTab = controller.tabBarController != nil && controller == controller.navigationController.viewControllers[0];
				controller.hidesBottomBarWhenPushed = YES;
				[controller.navigationController pushViewController:controllerToPresent animated:YES];
				if (isRootViewWithTab) {
					controller.hidesBottomBarWhenPushed = NO;
				}
			}
		}
	}
}

-(UIViewController *)controllerToPresent {
	if (self.rowDescriptor.action.viewControllerClass) {
		return [[self.rowDescriptor.action.viewControllerClass alloc] init];
	}
	else if ([self.rowDescriptor.action.viewControllerStoryboardId length] != 0){
		UIStoryboard * storyboard =  [self storyboardToPresent];
		NSAssert(storyboard != nil, @"You must provide a storyboard when rowDescriptor.action.viewControllerStoryboardId is used");
		return [storyboard instantiateViewControllerWithIdentifier:self.rowDescriptor.action.viewControllerStoryboardId];
	}
	else if ([self.rowDescriptor.action.viewControllerNibName length] != 0){
		Class viewControllerClass = NSClassFromString(self.rowDescriptor.action.viewControllerNibName);
		NSAssert(viewControllerClass, @"class owner of self.rowDescriptor.action.viewControllerNibName must be equal to %@", self.rowDescriptor.action.viewControllerNibName);
		return [[viewControllerClass alloc] initWithNibName:self.rowDescriptor.action.viewControllerNibName bundle:nil];
	}
	return nil;
}

-(UIStoryboard *)storyboardToPresent {
	if ([self.formViewController respondsToSelector:@selector(storyboardForRow:)]){
		return [self.formViewController storyboardForRow:self.rowDescriptor];
	}
	if (self.formViewController.storyboard){
		return self.formViewController.storyboard;
	}
	return nil;
}

+ (CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor {
	return 50;
}

@end