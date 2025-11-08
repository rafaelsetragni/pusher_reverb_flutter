abstract class ServiceException {}

abstract class ServiceChannelException extends ServiceException {}

abstract class ServiceConnectionException extends ServiceException {}

class NotConnectedException extends ServiceChannelException {}

class InvalidChannelNameException extends ServiceChannelException {}

class ChannelException extends ServiceChannelException {}
