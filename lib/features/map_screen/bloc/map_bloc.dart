import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:vietmap_flutter_gl/vietmap_flutter_gl.dart';
import 'package:vietmap_map/domain/repository/history_search_repositories.dart';
import 'package:vietmap_map/domain/repository/vietmap_api_repositories.dart';
import 'package:vietmap_map/domain/usecase/search_address_usecase.dart';
import '../../../core/no_params.dart';
import '../../../di/app_context.dart';
import '../../../domain/entities/vietmap_routing_params.dart';
import '../../../domain/usecase/add_history_search_usecase.dart';
import '../../../domain/usecase/get_direction_usecase.dart';
import '../../../domain/usecase/get_history_search_usecase.dart';
import '../../../domain/usecase/get_location_from_latlng_usecase.dart';
import '../../../domain/usecase/get_place_detail_usecase.dart';
import '../../../domain/usecase/get_point_from_category_usecase.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(MapStateInitial()) {
    on<MapEventSearchAddress>(_onMapEventSearchAddress);
    on<MapEventGetDetailAddress>(_onMapEventGetDetailAddress);
    on<MapEventGetDirection>(_onMapEventGetDirection);
    on<MapEventGetAddressFromCoordinate>(_onMapEventGetAddressFromCoordinate);
    on<MapEventOnUserLongTapOnMap>(_onMapEventOnUserLongTapOnMap);
    on<MapEventGetHistorySearch>(_onMapEventGetHistorySearch);
    on<MapEventGetAddressFromCategory>(_onMapEventGetAddressFromCategory);
    on<MapEventShowPlaceDetail>(_onMapEventShowPlaceDetail);
  }

  _onMapEventShowPlaceDetail(
      MapEventShowPlaceDetail event, Emitter<MapState> emit) async {
    emit(MapStateLoading());
    emit(MapStateGetLocationFromCoordinateSuccess(event.model));
  }

  _onMapEventGetAddressFromCategory(
      MapEventGetAddressFromCategory event, Emitter<MapState> emit) async {
    emit(MapStateLoading());
    EasyLoading.show();

    var response =
        await GetLocationFromCategoryUseCase(VietmapApiRepositories()).call(
            LocationPoint(
                lat: event.latLng?.latitude ?? 0,
                long: event.latLng?.longitude ?? 0,
                category: event.categoryCode));
    EasyLoading.dismiss();
    response.fold((l) => emit(MapStateSearchAddressError('Error')),
        (r) => emit(MapStateGetCategoryAddressSuccess(r)));
  }

  _onMapEventGetHistorySearch(
      MapEventGetHistorySearch event, Emitter<MapState> emit) async {
    emit(MapStateLoading());
    EasyLoading.show();
    var response = await GetHistorySearchUseCase(HistorySearchRepositories())
        .call(NoParams());
    EasyLoading.dismiss();
    response.fold((l) => emit(MapStateGetHistorySearchError('Error')),
        (r) => emit(MapStateGetHistorySearchSuccess(r)));
  }

  _onMapEventOnUserLongTapOnMap(
      MapEventOnUserLongTapOnMap event, Emitter<MapState> emit) async {
    add(MapEventGetAddressFromCoordinate(coordinate: event.coordinate));
  }

  _onMapEventGetAddressFromCoordinate(
      MapEventGetAddressFromCoordinate event, Emitter<MapState> emit) async {
    emit(MapStateLoading());
    EasyLoading.show();
    var response = await GetLocationFromLatLngUseCase(VietmapApiRepositories())
        .call(LocationPoint(
            lat: event.coordinate.latitude, long: event.coordinate.longitude));
    EasyLoading.dismiss();
    response.fold((l) => emit(MapStateGetLocationFromCoordinateError('Error')),
        (r) => emit(MapStateGetLocationFromCoordinateSuccess(r)));
  }

  _onMapEventGetDirection(
      MapEventGetDirection event, Emitter<MapState> emit) async {
    emit(MapStateLoading());
    EasyLoading.show();
    var response = await GetDirectionUseCase(VietmapApiRepositories()).call(
        VietMapRoutingParams(
            originPoint: event.from,
            destinationPoint: event.to,
            apiKey: AppContext.getVietmapAPIKey() ?? ''));
    response.fold((l) => MapStateGetDirectionError('Error'), (r) {
      var locs =
          PolylinePoints().decodePolyline(r.paths!.first.points!).map((e) {
        return LatLng(e.latitude, e.longitude);
      }).toList();
      emit(MapStateGetDirectionSuccess(r, locs));
    });
    EasyLoading.dismiss();
  }

  _onMapEventGetDetailAddress(
      MapEventGetDetailAddress event, Emitter<MapState> emit) async {
    emit(MapStateLoading());
    EasyLoading.show();
    AddHistorySearchUseCase(HistorySearchRepositories()).call(event.model);
    var response = await GetPlaceDetailUseCase(VietmapApiRepositories())
        .call(event.model.refId ?? '');
    EasyLoading.dismiss();
    response.fold((l) => emit(MapStateGetPlaceDetailError('Error')), (r) {
      emit(MapStateGetPlaceDetailSuccess(r));
    });
  }

  _onMapEventSearchAddress(
      MapEventSearchAddress event, Emitter<MapState> emit) async {
    emit(MapStateLoading());
    EasyLoading.show();
    var response = await SearchAddressUseCase(VietmapApiRepositories())
        .call(event.address);
    EasyLoading.dismiss();
    response.fold((l) => emit(MapStateSearchAddressError('Error')),
        (r) => emit(MapStateSearchAddressSuccess(r)));
  }
}
