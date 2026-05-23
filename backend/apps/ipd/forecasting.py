import pandas as pd
import numpy as np
from statsmodels.tsa.arima.model import ARIMA
from statsmodels.tsa.stattools import adfuller
from datetime import datetime, timedelta
import warnings

warnings.filterwarnings('ignore')


class DiseaseForecaster:
    """
    ARIMA-based forecasting for disease trends.
    Uses historical patient admission data to predict future cases.
    """
    
    def __init__(self, disease_name, historical_data):
        """
        Initialize forecaster with disease name and historical data.
        
        Args:
            disease_name: Name of the disease
            historical_data: List of dicts with 'date' and 'cases' keys
        """
        self.disease_name = disease_name
        self.historical_data = historical_data
        self.model = None
        self.fitted_model = None
        self.forecast_data = None
        
    def prepare_data(self):
        """Convert historical data to pandas Series for ARIMA."""
        df = pd.DataFrame(self.historical_data)
        df['date'] = pd.to_datetime(df['date'])
        df = df.sort_values('date').set_index('date')
        return df['cases']
    
    def check_stationarity(self, timeseries):
        """Check if time series is stationary using ADF test."""
        result = adfuller(timeseries.dropna())
        return result[1] < 0.05  # p-value < 0.05 means stationary
    
    def find_optimal_arima_params(self, timeseries, max_p=5, max_d=2, max_q=5):
        """
        Find optimal ARIMA parameters using grid search.
        Returns (p, d, q) tuple with lowest AIC.
        """
        best_aic = np.inf
        best_params = (0, 0, 0)
        
        for p in range(max_p + 1):
            for d in range(max_d + 1):
                for q in range(max_q + 1):
                    try:
                        model = ARIMA(timeseries, order=(p, d, q))
                        fitted = model.fit()
                        if fitted.aic < best_aic:
                            best_aic = fitted.aic
                            best_params = (p, d, q)
                    except:
                        continue
        
        return best_params
    
    def fit_model(self, order=None):
        """
        Fit ARIMA model to historical data.
        If order is None, automatically find optimal parameters.
        """
        timeseries = self.prepare_data()
        
        if order is None:
            order = self.find_optimal_arima_params(timeseries)
        
        self.model = ARIMA(timeseries, order=order)
        self.fitted_model = self.model.fit()
        
        return {
            'disease': self.disease_name,
            'arima_order': order,
            'aic': self.fitted_model.aic,
            'bic': self.fitted_model.bic,
        }
    
    def forecast(self, periods=12):
        """
        Generate forecast for specified number of periods (months).
        
        Args:
            periods: Number of months to forecast
            
        Returns:
            List of dicts with 'date', 'forecast', 'lower_ci', 'upper_ci'
        """
        if self.fitted_model is None:
            self.fit_model()
        
        forecast_result = self.fitted_model.get_forecast(steps=periods)
        forecast_df = forecast_result.summary_frame()
        
        # Get last date from historical data
        timeseries = self.prepare_data()
        last_date = timeseries.index[-1]
        
        # Generate forecast dates
        forecast_dates = [
            last_date + timedelta(days=30 * (i + 1)) 
            for i in range(periods)
        ]
        
        # Prepare forecast data
        forecast_list = []
        for i, date in enumerate(forecast_dates):
            forecast_list.append({
                'date': date.strftime('%Y-%m-%d'),
                'forecast': max(0, round(forecast_df['mean'].iloc[i], 2)),
                'lower_ci': max(0, round(forecast_df['mean_ci_lower'].iloc[i], 2)),
                'upper_ci': max(0, round(forecast_df['mean_ci_upper'].iloc[i], 2)),
            })
        
        self.forecast_data = forecast_list
        return forecast_list
    
    def get_forecast_summary(self):
        """Get summary statistics of the forecast."""
        if not self.forecast_data:
            return None
        
        forecasts = [f['forecast'] for f in self.forecast_data]
        
        return {
            'disease': self.disease_name,
            'avg_forecast': round(np.mean(forecasts), 2),
            'max_forecast': round(np.max(forecasts), 2),
            'min_forecast': round(np.min(forecasts), 2),
            'trend': 'Rising' if forecasts[-1] > forecasts[0] else 'Falling' if forecasts[-1] < forecasts[0] else 'Stable',
            'confidence_level': '95%',
        }


class MultiDiseaseForecaster:
    """Manages forecasting for multiple diseases."""
    
    def __init__(self):
        self.forecasters = {}
    
    def add_disease(self, disease_name, historical_data):
        """Add a disease for forecasting."""
        forecaster = DiseaseForecaster(disease_name, historical_data)
        self.forecasters[disease_name] = forecaster
    
    def forecast_all(self, periods=12):
        """Generate forecasts for all diseases."""
        results = {}
        for disease_name, forecaster in self.forecasters.items():
            try:
                model_info = forecaster.fit_model()
                forecast = forecaster.forecast(periods=periods)
                summary = forecaster.get_forecast_summary()
                
                results[disease_name] = {
                    'model_info': model_info,
                    'forecast': forecast,
                    'summary': summary,
                }
            except Exception as e:
                results[disease_name] = {
                    'error': str(e),
                }
        
        return results
    
    def get_alerts(self, threshold_increase=25):
        """
        Generate alerts for diseases with significant forecast increases.
        
        Args:
            threshold_increase: Percentage increase threshold for alert
        """
        alerts = []
        
        for disease_name, forecaster in self.forecasters.items():
            if not forecaster.forecast_data:
                continue
            
            timeseries = forecaster.prepare_data()
            current = timeseries.iloc[-1]
            forecast_avg = np.mean([f['forecast'] for f in forecaster.forecast_data])
            
            percent_change = ((forecast_avg - current) / current * 100) if current > 0 else 0
            
            if percent_change > threshold_increase:
                alerts.append({
                    'disease': disease_name,
                    'alert_type': 'High Increase Expected',
                    'current_cases': int(current),
                    'forecast_avg': round(forecast_avg, 2),
                    'percent_change': round(percent_change, 2),
                    'severity': 'High' if percent_change > 50 else 'Medium',
                })
            elif percent_change < -threshold_increase:
                alerts.append({
                    'disease': disease_name,
                    'alert_type': 'Significant Decrease Expected',
                    'current_cases': int(current),
                    'forecast_avg': round(forecast_avg, 2),
                    'percent_change': round(percent_change, 2),
                    'severity': 'Low',
                })
        
        return sorted(alerts, key=lambda x: abs(x['percent_change']), reverse=True)
