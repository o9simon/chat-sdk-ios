//
//  BSearchViewController.m
//  Chat SDK
//
//  Created by Benjamin Smiley-andrews on 27/05/2014.
//  Copyright (c) 2014 deluge. All rights reserved.
//

#import "BSearchViewController.h"

#import <ChatSDK/Core.h>
#import <ChatSDK/UI.h>

#define bCellIdentifier @"bCellIdentifier"

@interface BSearchViewController ()

@end

@implementation BSearchViewController

@synthesize tableView;
@synthesize usersSelected;
@synthesize addButton = _addButton;
@synthesize selectedUsers = _selectedUsers;
@synthesize currentSearchIndex = _currentSearchIndex;
@synthesize searchTermNavigationController = _searchTermNavigationController;

-(instancetype) initWithUsersToExclude: (NSArray *) excludedUsers {
    return [self initWithUsersToExclude:excludedUsers selectedAction:Nil];
}

-(instancetype) initWithUsersToExclude: (NSArray *) excludedUsers selectedAction: (void(^)(NSArray * users)) action {
    
    self = [super initWithNibName:@"BSearchViewController" bundle:[NSBundle uiBundle]];
    if (self) {
        _users = [NSMutableArray new];
        _selectedUsers = [NSMutableArray new];
        
        self.title = [NSBundle t: bSearch];
       
        _usersToExclude = excludedUsers;
        self.usersSelected = action;
        
        _searchController = [[UISearchController alloc] initWithSearchResultsController:Nil];
        _searchController.searchResultsUpdater = self;
        _searchController.delegate = self;
        _searchController.searchBar.delegate = self;

        _searchController.hidesNavigationBarDuringPresentation = NO;
        _searchController.dimsBackgroundDuringPresentation = NO;
        
        self.navigationItem.titleView = _searchController.searchBar;
        self.definesPresentationContext = YES;
        
        if (@available(iOS 11, *)) {
            self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
        }
        
    }
    return self;
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController_ {
    [self searchBarSearchButtonClicked:searchController_.searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString * string = searchBar.text;
    
    BOOL shouldSearch = [string stringByReplacingOccurrencesOfString:@" " withString:@""].length;
    
    if (shouldSearch && string.length > 2) {
        [self searchWithText:string];
    }
}

- (void)didPresentSearchController:(UISearchController *)searchController {
    searchController.searchBar.showsCancelButton = NO;
}

- (void)willPresentSearchController:(UISearchController *)searchController {
    searchController.searchBar.showsCancelButton = NO;
}

-(void) setExcludedUsers: (NSArray *) excludedUsers {
    _usersToExclude = excludedUsers;
}

-(void) setSelectedAction: (void(^)(NSArray * users)) action {
    self.usersSelected = action;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchTextField.rightViewMode = UITextFieldViewModeAlways;
    _searchTextFieldRightView = self.searchTextField.rightView;
    
    if ([BChatSDK.search respondsToSelector:@selector(availableIndexes)]) {
        // Get the search terms...
        [self startActivityIndicator];
        
        __weak __typeof__(self) weakSelf = self;

        [BChatSDK.search availableIndexes].thenOnMain(^id(NSArray * indexes) {
            __typeof__(self) strongSelf = weakSelf;
            
            NSMutableArray * nonRequiredIndexes = [NSMutableArray new];
            
            for(NSArray * index in indexes) {
                if(![index required]) {
                    [nonRequiredIndexes addObject:index];
                }
            }
            
            if (!indexes.count) {
                [strongSelf hideSearchTermButton];
            }
            else {
                strongSelf->_searchTermButtonEnabled = YES;
                strongSelf.currentSearchIndex = nonRequiredIndexes.firstObject;
                [strongSelf showSearchTermButton];
            }
           
            strongSelf.searchTermNavigationController = [BChatSDK.ui searchIndexNavigationControllerWithIndexes:nonRequiredIndexes withCallback:^(NSArray * index) {
                strongSelf.currentSearchIndex = index;
                [strongSelf showSearchTermButton];
            }];
            
            [strongSelf stopActivityIndicator];
            return Nil;
        }, Nil);
    }
    else {
        [self stopActivityIndicator];
        [self hideSearchTermButton];
    }
    
    // Add a tap recognizer to dismiss the keyboard
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle t:bBack] style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed)];

    _addButton = [[UIBarButtonItem alloc] initWithTitle:[NSBundle t:bAdd] style:UIBarButtonItemStylePlain target:self action:@selector(addButtonPressed)];
    self.navigationItem.rightBarButtonItem = _addButton;
    
    [tableView registerNib:[UINib nibWithNibName:@"BUserCell" bundle:[NSBundle uiBundle]] forCellReuseIdentifier:bCellIdentifier];
    
    self.noUsersFoundLabel.text = [NSBundle t:bNoNewUsersFoundForThisSearch];
    self.noUsersFoundView.hidden = YES;
    
    [self updateAddButton];
}

-(void) updateAddButton {
    if (_searchTermButtonEnabled && !_selectedUsers.count) {
        [self showSearchTermButton];
    }
    else {
        [self hideSearchTermButton];
    }
    _addButton.enabled = _selectedUsers.count;
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [_selectedUsers removeAllObjects];
    
    // Observe for keyboard appear and disappear notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:Nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:Nil];
    
    [self clearAndReload];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _internetConnectionObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification object:nil queue:Nil usingBlock:^(NSNotification * notification) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![Reachability reachabilityForInternetConnection].isReachable) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(UITextField *) searchTextField {
    for (UIView * container in _searchController.searchBar.subviews) {
        for (UIView * v in container.subviews) {
            if ([v isKindOfClass:[UITextField class]]) {
                return (UITextField *) v;
            }
        }
    }
    return Nil;
}

-(void) startActivityIndicator {
    if (_activityIndicator == Nil) {
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.transform = CGAffineTransformMakeScale(1, 1);
    }
    [_activityIndicator startAnimating];
    
    self.searchTextField.rightView =_activityIndicator;
    self.searchTextField.rightViewMode = UITextFieldViewModeAlways;
}

-(void) stopActivityIndicator {
    self.searchTextField.rightView = _searchTextFieldRightView;
}

-(void) showSearchTermButton {
    [self showSearchTermButton:_currentSearchIndex.key];
}

-(void) showSearchTermButton: (NSString *) text {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStylePlain target:self action:@selector(searchTermButtonPressed:)];
}

-(void) hideSearchTermButton {
    self.navigationItem.rightBarButtonItem = _addButton;
}

-(void) backButtonPressed {
    if (usersSelected != Nil) {
        usersSelected(@[]);
    }
}

-(void) addButtonPressed {
    if (usersSelected != Nil) {
        usersSelected(_selectedUsers);
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BUserCell * cell = [tableView_ dequeueReusableCellWithIdentifier:bCellIdentifier];

    // Get the user
    id<PUser> user = _users[indexPath.row];
    [cell setUser:user];
    cell.statusImageView.hidden = YES;
        
    if ([_selectedUsers containsObject:user]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView_ didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id<PUser> user = _users[indexPath.row];
    
    if ([_selectedUsers containsObject:user]) {
        [_selectedUsers removeObject:user];
    }
    else {
        [_selectedUsers addObject:user];
    }
    [tableView_ reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateAddButton];
}

-(void) searchWithText: (NSString *) text {
    
    [self clearAndReload];
    [self startActivityIndicator];
    
    NSArray * indexes = _currentSearchIndex.value ? @[_currentSearchIndex.value] : Nil;

    __weak __typeof__(self) weakSelf = self;

    [BChatSDK.search usersForIndexes:indexes withValue:text limit: 10 userAdded: ^(id<PUser> user) {
        __typeof__(self) strongSelf = weakSelf;

        // Make sure we run this on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (user != BChatSDK.currentUser) {
                // Only display a user if they have a name set
            
                // Check the users entityID to make sure they're not in the exclude list
                if (!strongSelf->_usersToExclude || ![strongSelf->_usersToExclude containsObject:user]) {
                    if (user.name.length) {
                        if (![strongSelf->_users containsObject:user]) {
                            [strongSelf->_users addObject:user];
                        }
                    }
                }
            }
            [strongSelf->_users sortUsersInAlphabeticalOrder];
            
            [strongSelf.tableView reloadData];
            
        });
        
    }].thenOnMain(^id(id success) {
        __typeof__(self) strongSelf = weakSelf;

        strongSelf.noUsersFoundView.hidden = strongSelf->_users.count > 0;
        
        [strongSelf.tableView reloadData];
        [strongSelf stopActivityIndicator];
        return Nil;
    }, ^id(NSError * error) {
        __typeof__(self) strongSelf = weakSelf;
        [strongSelf stopActivityIndicator];
        return error;
    });
}

#pragma TextField delegate

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self clearAndReload];
    return YES;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
    [self hideSearchTermButton];
    [self stopActivityIndicator];
    [self clearAndReload];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (!searchText || !searchText.length) {
        [self clearAndReload];
    }
}

-(void) clearAndReload {
    [_users removeAllObjects];
    [_selectedUsers removeAllObjects];
    [tableView reloadData];
}

- (void)searchTermButtonPressed:(id)sender {
    [self presentViewController:_searchTermNavigationController
                       animated:YES
                     completion:Nil];
}

-(void) keyboardWillShow: (NSNotification *) notification {
    
    // Get the keyboard size
    CGRect keyboardBounds = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardBoundsConverted = [self.view convertRect:keyboardBounds toView:Nil];
    
    // Get the duration and curve from the notification
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    // Set the new constraints
    tableView.keepBottomInset.equal = keyboardBoundsConverted.size.height;
    [self.view setNeedsUpdateConstraints];
    
    // Animate using this style because for some reason
    // using blocks doesn't give a smooth animation
    [UIView beginAnimations:Nil context:Nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:duration.doubleValue];
    [UIView setAnimationCurve:curve.integerValue];
    
    [self.view layoutIfNeeded];
    
    [UIView commitAnimations];
}

-(void) keyboardWillHide: (NSNotification *) notification {
    
    NSNumber *duration = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    tableView.keepBottomInset.equal = 0;
    [self.view setNeedsUpdateConstraints];
    
    [UIView beginAnimations:Nil context:Nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:duration.doubleValue];
    [UIView setAnimationCurve:curve.integerValue];
    
    [self.view layoutIfNeeded];
    
    // Set the inset so it's correct when we animate back to normal
    [self setTableViewBottomContentInset:0];
    
    [UIView commitAnimations];
}

-(void) setTableViewBottomContentInset: (float) inset {
    UIEdgeInsets insets = tableView.contentInset;
    insets.bottom = inset;
    tableView.contentInset = insets;
}

@end
