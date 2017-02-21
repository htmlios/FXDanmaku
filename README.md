# FXDanmaku
![build](https://img.shields.io/badge/build-passing-green.svg)
![pod](https://img.shields.io/badge/Cocoapods-v1.0.0-blue.svg)
![compatible](https://img.shields.io/badge/compatible-Objective--C%2FSwift-yellow.svg)

High-performance danmaku with GCD, reusable items and customize configurations.

##Features

1. Except UI operations in main-thread, other operations are all finished in different dispatchQueues.
2. Followed producer-cosumer pattern with pthread lib.
3. Defined delegate protocol to handle click response or other events.
4. Methods to register resuable item. Defined **FXDanmakuItem** class for inheriting.
5. Many configurations to meet your product's requirements. Such as, the velocity of item, the order to insert item, the direction of item movement and so on.
6. Easy to use. Just three control: start(resume), pause, stop. Except that, most methods are thread-safe.
7. Adaptation to the change of device orientaion.

##Preview

![](http://wx3.sinaimg.cn/large/9161297cgy1fcylkah5mwg209n0h8npd.gif) 
![](http://wx2.sinaimg.cn/large/9161297cgy1fcylkvn3arg20hy0a1x6p.gif)

##Example
```
// setup danmaku view
FXDanmakuConfiguration *config = [FXDanmakuConfiguration defaultConfiguration];
config.rowHeight = [DemoDanmakuItem itemHeight];
self.danmaku.configuration = config;
self.danmaku.delegate = self;
[self.danmaku registerNib:[UINib nibWithNibName:NSStringFromClass([DemoDanmakuItem class]) bundle:nil]
   forItemReuseIdentifier:[DemoDanmakuItem reuseIdentifier]];
[self.danmaku registerClass:[DemoBulletinItem class] 
     forItemReuseIdentifier:[DemoBulletinItem reuseIdentifier]];

// add data for danmaku view to present
DemoDanmakuItemData *data = [DemoDanmakuItemData data];
[self.danmaku addData:data];

// start running
if (!self.danmaku.isRunning) {
	[self.danmaku start];
}

// FXDanmakuDelegate
- (void)danmaku:(FXDanmaku *)danmaku didClickItem:(FXDanmakuItem *)item withData:(DemoDanmakuItemData *)data {
	// handle click event here
}
```
More examples in `FXDanmakuDemo.xcworkspace`. 

Demo builded and ran in Xcode8.

##Q&A
1. Relationships among rowHeight、estimatedRowSpace and rowSpace
	
	![](http://wx3.sinaimg.cn/mw690/9161297cgy1fcyktlu5gnj20k80b475g.jpg)
	

##Requirements
FXDanmaku requires `iOS 7.0+`.

##Installation
#####Cocoapods(iOS7+)

1. Add these lines below to your Podfile 
	
	```
	platform :ios, 'xxx'
	pod 'FXDanmaku'
	```
2. Install the pod by running `pod install`

#####Manually(iOS7+)
Drag `FXDanmaku` document to your project

## License
FXDanmaku is provided under the MIT license. See LICENSE file for details.
