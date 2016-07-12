//
//  ListTableViewController.m
//  bookManager
//
//  Created by inouenaoto on 2016/07/02.
//  Copyright © 2016年 inouenaoto. All rights reserved.
//フッター　http://blog.7bunnies.com/2011/09/uitableviewtablefooterviewuibutton.html
//テーブル処理　https://gist.github.com/inonb/3157988#file-gistfile1-txt
//
//
//
//
#import <AFNetworking/AFNetworking.h>
#import"bookManagerAPI.h"
#import "ListTableViewController.h"
#import "ListTableCell.h"
#import "Read_More_Cell.h"
#import "EditViewController.h"
#define ONCE_READ_COUNT 1

@interface ListTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *Listtable;

@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (readwrite) NSInteger page;

@property (strong, nonatomic) NSMutableArray *title_list;
@property (strong, nonatomic) NSMutableArray *price_list;
@property (strong, nonatomic) NSMutableArray *date_list;
@property (strong, nonatomic) NSMutableArray *id_list;
@property (strong, nonatomic) NSString *set_date; //時間を書式変更したもの

@end

@implementation ListTableViewController

int total = 0;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"ListTableCell" bundle:nil] forCellReuseIdentifier:@"ListCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"Read_More_Cell" bundle:nil] forCellReuseIdentifier:@"ReadMoreCell"];

    total=2;
    _page = 1;
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [self.indicator setColor:[UIColor darkGrayColor]];
    [self.indicator setHidesWhenStopped:YES];
    [self.indicator stopAnimating];
//   NSLog(@"%@",_Price_Array);

}

- (void)viewWillAppear:(BOOL)animated {
    [self GetJson];
    NSLog(@"grt json %@",_title_list);
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 125;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _page*ONCE_READ_COUNT+1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSString *identifier = @"ListCell" ;
    ListTableCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    //最終セルの設定 http://qiita.com/yuto_aka_ike/items/6e2785499e5897725e22
    if(indexPath.row == _page*ONCE_READ_COUNT)
    {
        NSString *identifier = @"ReadMoreCell" ;
        Read_More_Cell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        [cell.Read_Button addTarget:self action:@selector(read_more_button:event:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
  }
        cell.title_label.text = [self.title_list objectAtIndex:indexPath.row];
        cell.price_label.text = [NSString stringWithFormat:@"%@円", self.price_list [indexPath.row]];
        cell.bookimage_view.image=[ UIImage imageNamed:@"book_sample.jpg" ];

    //　時間の書式変更「http://qiita.com/yuto_aka_ike/items/6e2785499e5897725e22」
    NSString *gmt = self.date_list[indexPath.row];
   
    NSDateFormatter *DF = [[NSDateFormatter alloc] init];
    [DF setDateFormat:@"EEE, dd MM yyy HH:mm:ss Z"];
    [DF setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"JP"]];
    NSDate *date = [DF dateFromString:gmt];
    
    //NSStringに
    NSDateFormatter *outFmt = [[NSDateFormatter alloc] init];
    [outFmt setDateFormat:@"yyyy/MM/dd"];
    _set_date = [outFmt stringFromDate:date];
    
    cell.date_label.text = _set_date;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
    
}
//テーブルのセルから移動

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"List_to_Edit" sender:self];
}

//セグエが編集画面へのものだった時にデータを渡す
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"List_to_Edit"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        EditViewController *editViewController = (EditViewController *)segue.destinationViewController;
        editViewController.selected_title = [self.title_list objectAtIndex:indexPath.row];
        editViewController.selected_price = [self.price_list objectAtIndex:indexPath.row];
        editViewController.selected_date = _set_date;
        editViewController.selected_id = [self.id_list objectAtIndex:indexPath.row];
        // editViewController.selected_price = [self.price_list objectAtIndex:indexPath.row];
//        editViewController.selected_date = [self.date_list objectAtIndex:indexPath.row];


    }
}

- (IBAction)addButtonTapped:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"List_to_Add" sender:self];
    
}


//もっと読みこむボタンのイベント
- (void)read_more_button:(UIButton *)sender event:(UIEvent *)event {
        
        if([_indicator isAnimating]) {
            return;
        }
        
        
        if (self.title_list.count > (_page*ONCE_READ_COUNT)) {
            [self startIndicator];
            [self performSelector:@selector(reloadMoreData) withObject:nil afterDelay:0.1f];
        }
        
    
}

/*　スクロールかボタンか迷い中なのでコメント化
//テーブルの「さらに読みこむ処理の追加
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //一番下までスクロールしたかどうか
    if(self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.size.height))
    {

        //まだ表示するコンテンツが存在するか判定し存在するなら○件分を取得して表示更新する処理をここに書く
    }
}
*/
//インディケータの設定
- (void)reloadMoreData
{
    _page++;
    [self.tableView reloadData];
    [self endIndicator];
}

- (void)startIndicator
{
    [_indicator startAnimating];
    CGRect footerFrame = self.tableView.tableFooterView.frame;
    footerFrame.size.height += 10.0f;
    
    [_indicator setFrame:footerFrame];
    [self.tableView setTableFooterView:_indicator];
}

- (void)endIndicator
{
    [_indicator stopAnimating];
    [_indicator removeFromSuperview];
    [self.tableView setTableFooterView:nil];
    
}
/*

#pragma mark - 表示セルの一番下まできたら次のONCE_READ_COUNT件数取得
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
    if(self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.size.height))
    {
        
        if([_indicator isAnimating]) {
            return;
        }
        
        
        if (total > (_page*ONCE_READ_COUNT)) {
            [self startIndicator];
            [self performSelector:@selector(reloadMoreData) withObject:nil afterDelay:0.1f];
        }
        
    }
}
*/
- (void)GetJson {

    NSString *url = @"http://app.com/book/get";
    NSDictionary *params = [[NSDictionary alloc] init];
    params = @{@"page":@"0-10"};
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager POST:url
       parameters:params
          success:^(NSURLSessionDataTask *operation, id responseObject) {
            //通信に成功した場合の処理
              NSArray *API_Array = [responseObject objectForKey:@"result"];
          
          
              //  NSLog(@"回数は%d", API_Array.count);
          
              NSArray * APIArray = [responseObject objectForKey:@"result"];
              NSMutableArray *ID_Array = [NSMutableArray array];
              NSMutableArray *Image_Array = [NSMutableArray array];
              NSMutableArray *Title_Array = [NSMutableArray array];
              NSMutableArray *Price_Array = [NSMutableArray array];
              NSMutableArray *Date_Array = [NSMutableArray array];
          
          
          //取得したAPIをそれぞれの配列に格納
          // NSLog(@"%@",API_Array);
          for(int i = 0; i < API_Array.count; i++) {
              [ID_Array addObject:[API_Array[i] objectForKey:@"id"]];
              [Image_Array addObject:[API_Array[i] objectForKey:@"image_url"]];
              [Title_Array addObject:[API_Array[i] objectForKey:@"name"]];
              [Price_Array addObject:[API_Array[i] objectForKey:@"price"]];
              [Date_Array addObject:[API_Array[i] objectForKey:@"purchase_date"]];

          }
          
            self.title_list = Title_Array;
            self.price_list = Price_Array;
            self.date_list = Date_Array;
            self.id_list = ID_Array;
           [self.Listtable reloadData];
              
 /*
                       NSLog(@"title %@", _title_list);
                       NSLog(@"%@", _price_list);
                       NSLog(@"%@", _date_list);
 */
          [self.tableView reloadData];
          
      } failure:^(NSURLSessionDataTask *operation, NSError *error) {
          NSLog(@"failed: %@", error);
      }];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

@end
