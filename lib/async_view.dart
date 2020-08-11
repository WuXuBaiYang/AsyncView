library async_view;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

//主视图构造器
typedef AsyncViewBuilder<T> = Widget Function(BuildContext context, T data);

//重试与加载构造器
typedef AsyncViewSimpleBuilder<T> = Widget Function(BuildContext context);

//future回调
typedef AsyncViewFuture<T> = Future<T> Function(BuildContext context);

/*
* 异步加载组件
* @author jtech
* @Time 2020/8/11 1:36 PM
*/
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    Key key,
    this.future,
    this.initialData,
    this.retryChildBuilder,
    this.loadingBuilder,
    @required this.builder,
  })  : assert(builder != null),
        super(key: key);

  //构造器
  final AsyncViewBuilder<T> builder;

  //重试视图子内容构造器
  final AsyncViewSimpleBuilder retryChildBuilder;

  //加载视图构造器
  final AsyncViewSimpleBuilder loadingBuilder;

  //异步方法
  final AsyncViewFuture<T> future;

  //初始数据
  final T initialData;

  @override
  _AsyncViewState createState() => _AsyncViewState();
}

/*
* 异步加载组件状态类
* @author jtech
* @Time 2020/8/11 1:39 PM
*/
class _AsyncViewState<T> extends State<AsyncView<T>> {
  Object _activeCallbackIdentity;
  AsyncSnapshot<T> _snapshot;

  @override
  void initState() {
    super.initState();
    _snapshot =
        AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData);
    _subscribe();
  }

  @override
  Widget build(BuildContext context) {
    if (_snapshot.hasData) {
      return widget.builder(context, _snapshot.data);
    }
    if (_snapshot.hasError) {
      return _buildRetry();
    }
    return _buildLoading();
  }

  //构建重试视图
  Widget _buildRetry() {
    return Center(
      child: InkWell(
        child: null != widget.retryChildBuilder
            ? widget.retryChildBuilder(context)
            : const Text("Retry"),
        onTap: () => setState(() => _retry()),
      ),
    );
  }

  //构建加载视图
  Widget _buildLoading() {
    return null != widget.loadingBuilder
        ? widget.loadingBuilder(context)
        : Center(child: const CircularProgressIndicator());
  }

  //回调重试请求
  void _retry() {
    if (_activeCallbackIdentity != null) {
      _unsubscribe();
      _snapshot =
          AsyncSnapshot<T>.withData(ConnectionState.none, widget.initialData);
    }
    _subscribe();
  }

  //监听请求状态
  void _subscribe() {
    if (null != widget.future) {
      final Object callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      widget.future(context).then<void>((T data) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data);
          });
        }
      }, onError: (error) {
        if (_activeCallbackIdentity == callbackIdentity) {
          setState(() {
            _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error);
          });
        }
      });
      _snapshot = _snapshot.inState(ConnectionState.waiting);
    }
  }

  //反监听
  void _unsubscribe() => _activeCallbackIdentity = null;

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
