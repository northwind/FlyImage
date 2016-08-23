//
//  RootViewController.m
//  Demo
//
//  Created by Ye Tong on 3/24/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "RootViewController.h"
#import "BaseTableViewCell.h"
#import "SDImageCache.h"

@interface RootViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation RootViewController {
	UITableView *_tableView;
	UISegmentedControl *_segment;
	
    NSMutableArray *_imageURLs;
    NSMutableArray *_cells;
    NSMutableArray *_indentifiers;
}

- (instancetype)init {
	if (self = [super init]) {
		_cells = [[NSMutableArray alloc] init];
		_indentifiers = [[NSMutableArray alloc] init];
		_activeIndex = 0;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
	
	// setup image paths
	_imageURLs = [[NSMutableArray alloc] init];
	for (int i=0; i<100; i++) {
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://flyimage.oss-us-west-1.aliyuncs.com/%d%@", i, self.suffix ]];
		[_imageURLs addObject:url];
	}
	
	CGFloat segmentHeight = 30;
	CGRect bounds = self.view.bounds;
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width, bounds.size.height-segmentHeight)
											  style:UITableViewStylePlain];
	_tableView.opaque = YES;
	_tableView.directionalLockEnabled = YES;
	_tableView.backgroundColor = [UIColor clearColor];
	_tableView.allowsSelection = NO;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_tableView.dataSource = self;
	_tableView.delegate = self;
	
	NSMutableArray *items = [NSMutableArray array];
	for (NSDictionary *info in _cells) {
		[items addObject: [info objectForKey:@"title"]];
		
		Class class = [info objectForKey:@"class"];
		NSString *indentifier = NSStringFromClass(class);
		[_indentifiers addObject:indentifier];
		[_tableView registerClass:class forCellReuseIdentifier:indentifier];
	}
	[self.view addSubview:_tableView];
	
	NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:10], NSFontAttributeName, nil];
	[[UISegmentedControl appearance] setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
	
	_segment = [[UISegmentedControl alloc] initWithItems:items];
	_segment.backgroundColor = [UIColor whiteColor];
	_segment.frame = CGRectMake(0, bounds.size.height - segmentHeight, bounds.size.width, segmentHeight);
	[_segment setSelectedSegmentIndex:_activeIndex];
	[_segment addTarget:self action:@selector(onTapSegment) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:_segment];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)onTapSegment {
	_activeIndex = _segment.selectedSegmentIndex;
	
	[_tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 2000;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return self.heightOfCell;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    NSInteger startIndex = ([indexPath row] * self.cellsPerRow) % [_imageURLs count];
    NSInteger count = MIN(self.cellsPerRow, [_imageURLs count] - startIndex);
    NSArray *photos = [_imageURLs subarrayWithRange:NSMakeRange(startIndex, count)];
    
	BaseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_indentifiers[_activeIndex] forIndexPath:indexPath];
    [cell displayImageWithPhotos:photos];

    return cell;
}

@end
