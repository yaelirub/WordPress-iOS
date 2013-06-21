//
//  ReaderPostTableViewCell.m
//  WordPress
//
//  Created by Eric J on 4/4/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "ReaderPostTableViewCell.h"
#import <DTCoreText/DTCoreText.h>
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+Gravatar.h"
#import "WordPressAppDelegate.h"
#import "WPWebViewController.h"
#import "UIImageView+AFNetworkingExtra.h"
#import "UILabel+SuggestSize.h"
#import "WPAvatarSource.h"

#define RPTVCVerticalPadding 10.0f;

static UIColor *ControlActiveColor;
static UIColor *ControlInactiveColor;

@interface ReaderPostTableViewCell()

@property (nonatomic, strong) ReaderPost *post;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *byView;
@property (nonatomic, strong) UIView *controlView;
@property (nonatomic, strong) UIButton *likeButton;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *reblogButton;
@property (nonatomic, strong) UILabel *bylineLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *snippetLabel;
@property (nonatomic, assign) BOOL showImage;

- (void)handleLikeButtonTapped:(id)sender;
- (void)handleFollowButtonTapped:(id)sender;

@end

@implementation ReaderPostTableViewCell {
    BOOL _featuredImageIsSet;
    BOOL _avatarIsSet;
}

+ (void)initialize {
    ControlActiveColor = [UIColor colorWithHexString:@"F1831E"];
	ControlInactiveColor = [UIColor colorWithHexString:@"3478E3"];
}

+ (CGFloat)cellHeightForPost:(ReaderPost *)post withWidth:(CGFloat)width {
	CGFloat desiredHeight = 0.0f;
	CGFloat vpadding = RPTVCVerticalPadding;

	// Do the math. We can't trust the cell's contentView's frame because
	// its not updated at a useful time during rotation.
	CGFloat contentWidth = width - 20.0f; // 10px padding on either side.

	// Are we showing an image? What size should it be?
	if(post.featuredImageURL) {
		CGFloat height = (contentWidth * 0.66f);
		desiredHeight += height;
	}

	desiredHeight += vpadding;

	desiredHeight += [post.postTitle sizeWithFont:[UIFont fontWithName:@"OpenSans-Light" size:20.0f] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height;
	desiredHeight += vpadding;

	desiredHeight += [post.summary sizeWithFont:[UIFont fontWithName:@"OpenSans" size:13.0f] constrainedToSize:CGSizeMake(contentWidth, CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap].height;
	desiredHeight += vpadding;

	// Size of the byview
	desiredHeight += 32.f;

	// size of the control bar
	desiredHeight += 40.f;

	desiredHeight += vpadding;

	return ceil(desiredHeight);
}

#pragma mark - Lifecycle Methods

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {

		self.contentView.backgroundColor = [UIColor colorWithHexString:@"F1F1F1"];
		CGRect frame = CGRectMake(10.0f, 0.0f, self.contentView.frame.size.width - 20.0f, self.contentView.frame.size.height - 10.0f);
		CGFloat width = frame.size.width;

		self.containerView = [[UIView alloc] initWithFrame:frame];
		_containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_containerView.backgroundColor = [UIColor whiteColor];
        _containerView.opaque = YES;
		[self.contentView addSubview:_containerView];

		/* TODO: add shadow without performance hit
		UIImage *image = [UIImage imageNamed:@"reader-post-cell-shadow.png"];
		UIImageView *dropShadow = [[UIImageView alloc] initWithImage:[image resizableImageWithCapInsets:UIEdgeInsetsMake(0.0f, 1.0f, 2.0f, 1.0f)]];
		dropShadow.frame = CGRectMake(-1.0f, 0.0f, width + 2, frame.size.height + 2);
		dropShadow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[_containerView addSubview:dropShadow];
         */
		
        self.cellImageView.contentMode = UIViewContentModeCenter;
        self.cellImageView.image = [UIImage imageNamed:@"wp_img_placeholder"];
        // FIXME: use darker color and make placeholder opaque
//        self.cellImageView.backgroundColor = self.contentView.backgroundColor;
		[_containerView addSubview:self.cellImageView];
				
		self.byView = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 0.0f, (width - 20.0f), 32.0f)];
		_byView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		[_containerView addSubview:_byView];
		
		self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
		[_byView addSubview:_avatarImageView];
		
		self.bylineLabel = [[UILabel alloc] initWithFrame:CGRectMake(37.0f, -2.0f, width - 57.0f, 36.0f)];
		_bylineLabel.numberOfLines = 2;
		_bylineLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_bylineLabel.font = [UIFont fontWithName:@"OpenSans" size:12.0f];
		_bylineLabel.adjustsFontSizeToFitWidth = NO;
		_bylineLabel.textColor = [UIColor colorWithHexString:@"c0c0c0"];
        _bylineLabel.backgroundColor = [UIColor whiteColor];
		[_byView addSubview:_bylineLabel];
		
		self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, width, 44.0f)];
		_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_titleLabel.backgroundColor = [UIColor whiteColor];
		_titleLabel.font = [UIFont fontWithName:@"OpenSans-Light" size:20.0f];
		_titleLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0];
		_titleLabel.lineBreakMode = UILineBreakModeWordWrap;
		_titleLabel.numberOfLines = 0;
		[_containerView addSubview:_titleLabel];

		self.snippetLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0.0, width, 44.0f)];
		_snippetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_snippetLabel.backgroundColor = [UIColor whiteColor];
		_snippetLabel.font = [UIFont fontWithName:@"OpenSans" size:13.0f];
		_snippetLabel.textColor = [UIColor colorWithRed:64.0f/255.0f green:64.0f/255.0f blue:64.0f/255.0f alpha:1.0];
		_snippetLabel.lineBreakMode = UILineBreakModeWordWrap;
		_snippetLabel.numberOfLines = 0;
		[_containerView addSubview:_snippetLabel];
		
		CGFloat fontSize = 16.0f;
		self.followButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_followButton.titleLabel setFont:[UIFont systemFontOfSize:fontSize]];
		[_followButton setTitle:NSLocalizedString(@"Follow", @"") forState:UIControlStateNormal];
		[_followButton setTitleColor:ControlInactiveColor forState:UIControlStateNormal];
		[_followButton setTitleColor:ControlActiveColor forState:UIControlStateSelected];
		[_followButton setImage:[UIImage imageNamed:@"note_icon_follow"] forState:UIControlStateNormal];
		[_followButton setImage:[UIImage imageNamed:@"note_navbar_icon_follow"] forState:UIControlStateSelected];
		_followButton.frame = CGRectMake(0.0f, 0.0f, 100.0f, 40.0f);
		[_followButton addTarget:self action:@selector(handleFollowButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

		self.likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_likeButton.titleLabel setFont:[UIFont systemFontOfSize:fontSize]];
		[_likeButton setTitle:NSLocalizedString(@"Like", @"") forState:UIControlStateNormal];
		[_likeButton setTitleColor:ControlInactiveColor forState:UIControlStateNormal];
		[_likeButton setTitleColor:ControlActiveColor forState:UIControlStateSelected];
		[_likeButton setImage:[UIImage imageNamed:@"note_icon_like"] forState:UIControlStateNormal];
		[_likeButton setImage:[UIImage imageNamed:@"note_navbar_icon_like"] forState:UIControlStateSelected];
		_likeButton.frame = CGRectMake(100.0f, 0.0f, 100.0f, 40.0f);
		_likeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[_likeButton addTarget:self action:@selector(handleLikeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

		self.reblogButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[_reblogButton.titleLabel setFont:[UIFont systemFontOfSize:fontSize]];
		[_reblogButton setTitle:NSLocalizedString(@"Reblog", @"") forState:UIControlStateNormal];
		[_reblogButton setTitleColor:ControlInactiveColor forState:UIControlStateNormal];
		[_reblogButton setTitleColor:ControlActiveColor forState:UIControlStateSelected];
		[_reblogButton setImage:[UIImage imageNamed:@"note_icon_reblog"] forState:UIControlStateNormal];
		[_reblogButton setImage:[UIImage imageNamed:@"note_navbar_icon_reblog"] forState:UIControlStateSelected];
		_reblogButton.frame = CGRectMake(200.0f, 0.0f, 100.0f, 40.0f);
		_reblogButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		
		self.controlView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, width, 40.0f)];
		_controlView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

		[_controlView addSubview:_followButton];
		[_controlView addSubview:_likeButton];
		[_controlView addSubview:_reblogButton];
		[_containerView addSubview:_controlView];
		
    }
	
    return self;
}


- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat contentWidth = _containerView.frame.size.width;
	CGFloat nextY = 0.0f;
	CGFloat vpadding = RPTVCVerticalPadding;
	CGFloat height = 0.0f;

	// Are we showing an image? What size should it be?
	if(_showImage) {
		height = ceil(contentWidth * 0.66f);
		self.cellImageView.frame = CGRectMake(0.0f, nextY, contentWidth, height);
		nextY += height + vpadding;
	} else {
		nextY += vpadding;
	}

	// Position the title
	height = ceil([_titleLabel suggestedSizeForWidth:contentWidth].height);
	_titleLabel.frame = CGRectMake(10.0f, nextY, contentWidth-20.0f, height);
	nextY += height + vpadding;

	// Position the snippet
	height = ceil([_snippetLabel suggestedSizeForWidth:contentWidth].height);
	_snippetLabel.frame = CGRectMake(10.0f, nextY, contentWidth-20.0f, height);
	nextY += height + vpadding;
	
//	height = [self.textContentView suggestedFrameSizeToFitEntireStringConstraintedToWidth:contentWidth].height;
//	self.textContentView.frame = CGRectMake(0.0f, nextY, contentWidth, height);
//	[self.textContentView layoutSubviews];
//	nextY += ceilf(height + vpadding);

	// position the byView
	height = _byView.frame.size.height;
	CGFloat width = contentWidth - 20.0f;
	_byView.frame = CGRectMake(10.0f, nextY, width, height);
	nextY += ceilf(height + vpadding);
	
	// position the control bar
	height = _controlView.frame.size.height;
	_controlView.frame = CGRectMake(0.0f, nextY, contentWidth, height);
}


- (void)prepareForReuse {
	[super prepareForReuse];

    self.cellImageView.contentMode = UIViewContentModeCenter;
    self.cellImageView.image = [UIImage imageNamed:@"wp_img_placeholder"];
    _featuredImageIsSet = NO;
    _avatarIsSet = NO;

	_avatarImageView.image = nil;
	_bylineLabel.text = nil;
}


#pragma mark - Instance Methods

- (void)setReblogTarget:(id)target action:(SEL)selector {
	[_reblogButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureCell:(ReaderPost *)post {
	self.post = post;

	_titleLabel.text = [post.postTitle trim];
	_snippetLabel.text = post.summary;
	
	_bylineLabel.text = [NSString stringWithFormat:@"%@ \non %@", [post prettyDateString], post.blogName];

	self.showImage = NO;
	self.cellImageView.hidden = YES;
	if (post.featuredImageURL) {
		self.showImage = YES;
		self.cellImageView.hidden = NO;

		NSInteger width = ceil(_containerView.frame.size.width);
        NSInteger height = (width * 0.66f);
        CGRect imageFrame = self.cellImageView.frame;
        imageFrame.size.width = width;
        imageFrame.size.height = height;
        self.cellImageView.frame = imageFrame;
	}
	
	_reblogButton.hidden = ![self.post isWPCom];
	
	CGFloat padding = (self.containerView.frame.size.width - ( _followButton.frame.size.width * 3.0f ) ) / 2.0f;
	CGRect frame;
	if( [self.post isBlogsIFollow] ) {
		_followButton.hidden = YES;
		frame = _likeButton.frame;
		frame.origin.x = 0.0f;
		_likeButton.frame = frame;
		
		frame = _reblogButton.frame;
		frame.origin.x = _likeButton.frame.size.width + padding;
		_reblogButton.frame = frame;
		
	} else {
		_followButton.hidden = NO;

		frame = _likeButton.frame;
		frame.origin.x = _followButton.frame.size.width + padding;
		_likeButton.frame = frame;
		
		frame = _reblogButton.frame;
		frame.origin.x = _likeButton.frame.size.width + _likeButton.frame.origin.x + padding;
		_reblogButton.frame = frame;
	}

	[self updateControlBar];
}

- (void)setAvatar:(UIImage *)avatar {
    if (_avatarIsSet) {
        return;
    }
    static UIImage *wpcomBlavatar;
    static UIImage *wporgBlavatar;
    if (!wpcomBlavatar) {
        wpcomBlavatar = [UIImage imageNamed:@"wpcom_blavatar"];
    }
    if (!wporgBlavatar) {
        wporgBlavatar = [UIImage imageNamed:@"wporg_blavatar"];
    }

    if (avatar) {
        self.avatarImageView.image = avatar;
        _avatarIsSet = YES;
    } else {
        self.avatarImageView.image = [self.post isWPCom] ? wpcomBlavatar : wporgBlavatar;
    }
}

- (void)setFeaturedImage:(UIImage *)image {
    if (_featuredImageIsSet) {
        return;
    }
    _featuredImageIsSet = YES;
    self.cellImageView.image = image;
}

- (void)updateControlBar {
	if (!_post) return;
	
    _likeButton.selected = _post.isLiked.boolValue;
    _followButton.selected = _post.isFollowing.boolValue;
    _reblogButton.selected = _post.isReblogged.boolValue;

	NSString *likeStr = NSLocalizedString(@"Like", @"Like button title.");
	if ([self.post.likeCount integerValue] > 0) {
		likeStr = [NSString stringWithFormat:@"%@ (%@)", likeStr, [self.post.likeCount stringValue]];
	}
	[_likeButton setTitle:likeStr forState:UIControlStateNormal];
}


- (void)handleLikeButtonTapped:(id)sender {

	[self.post toggleLikedWithSuccess:^{
		// Nothing to see here?
	} failure:^(NSError *error) {
		WPLog(@"Error Liking Post : %@", [error localizedDescription]);
		[self updateControlBar];
	}];
	
	[self updateControlBar];
}


- (void)handleFollowButtonTapped:(id)sender {
	[self.post toggleFollowingWithSuccess:^{
		
	} failure:^(NSError *error) {
		WPLog(@"Error Following Blog : %@", [error localizedDescription]);
		[self updateControlBar];
	}];
	
	[self updateControlBar];
}


@end
