//
//  ArticleTableViewCell.h
//  inspire
//
//  Created by Yuji on 2015/08/28.
//
//

#import <UIKit/UIKit.h>

@interface ArticleTableViewCell : UITableViewCell
@property (strong,nonatomic) IBOutlet UILabel*title;
@property (strong,nonatomic) IBOutlet UILabel*authors;
@property (strong,nonatomic) IBOutlet UILabel*eprint;
@end
