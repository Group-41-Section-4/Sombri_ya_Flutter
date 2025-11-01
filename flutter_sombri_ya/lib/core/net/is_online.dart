import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/blocs/connectivity/connectivity_cubit.dart';
import '../connectivity/connectivity_service.dart'; 

bool isOnline(BuildContext context) {
  final status = context.read<ConnectivityCubit>().state;
  return status == ConnectivityStatus.online;
}
