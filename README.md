# FXTrackView
A high-performance trackview to present data asynchronously.

##Preview

![](http://ww2.sinaimg.cn/mw690/9161297cgw1f2mbjbevljj20e30p0wiy.jpg)

![](http://ww3.sinaimg.cn/mw690/9161297cgw1f2mbhrh6lqj20u00gw7cl.jpg)

##Features

1. Created 4 serial dispatch_queues to do different jobs asynchronously
	* consumerQueue: fetch unoccupied tracks and dispatch data to each unoccupied track
	* trackProducerQueue: reset occupied track
	* dataProducerQueue: check validity of data, and add it into dataQueue
	* computationQueue:  calculate random velocity of track, animation duration, time of resetting track as well as startPoint of data
2. Followed producer-cosumer pattern. Also, to prevent from data race I have used **pthread lib**
3. Data can be CustomView or AttributedText
4. Method to handle device orientation changed, which might cause trackView's frame changed
5. Two priority levels(Normal/High) for presenting data
6. Random velocity of each data
7. Easy to use. Only three control methods: start(resume), pause, stop


## Note
`Document are still in progress. Please wait for a few more days.`
