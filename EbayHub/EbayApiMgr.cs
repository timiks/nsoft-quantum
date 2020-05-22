using eBay.Service.Call;
using eBay.Service.Core.Sdk;
using eBay.Service.Core.Soap;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Quantum.EbayHub
{
    enum EbayApiRequestMode
    { 
        AuthUser,
        Developer
    }

    enum ResultSortOrder
    {
        Ascending,
        Descending
    }
    
    class EbayApiMgr
    {
        private const string ApiServerUrl = "https://api.ebay.com/wsapi"; // Production server

        private const string UserAuthTokenTemp = "AgAAAA**AQAAAA**aAAAAA**MpG5Xg**nY+sHZ2PrBmdj6wVnY+sEZ2PrA2dj6MFkYqhC5OBpwmdj6x9nY+seQ**Ak0GAA**AAMAAA**NTqDYBZBI36bP+Ygr4tD+P6wmsMFJi9NUDx6lrRnesFmaX+foxARVSwHTG3dBd1EnKo5+igiy8RRcv3s5joClaDklsOrWKSLJ3attcRQeyt9uLhVekrKbzulhDoaLS4Nbyu7as+yYPuh2vGrvNucaH364v0ICOg/yuCbfLRZHKR7ALjDdcolkCiVu7r+rPxEt9tLRhQO2d8JB3adYwu1PwOaYPQ7OBSv/DO84AhG2vIaS5/5WexJox2W/OLAux6zT4V/u6cQ7bgeRnUCvFAeaffl4OzGBaMV5nV+dI81plpCpbTTPkxW1by4RyIc4rZRnBFnmWKiiQF0Sr2nQUUsqLSOWlIcwBtve/s3VRzxomlwXhdo1zyrYrW6AGkTwO1LGr0AmTByyDiplqyinc8MynwWXkDDIpLqGYx/y4f2FWK28XqD9R+EJr94DYw5TPQzV9f+KAmGeQkKUr5r6D8opYcRpoOJ+fIvAdUVbVvThuqp5PC0LSGh0VO+9XAJBdjoEJu5hl/81XphGUQ2u3cXb5o+6PFo8p9Pb70OmrPfbv46GK4leuD27zcmUn91P+qhjDoQFuRkEuWPqOC1Uk0eBNvTbXEsTD/tUgMcFJO/VqGYUYIfcJMklT40PYCEMJcNY/25i5itV9GmnGeFuMAHs6Yr2gY1s3RAbAaX53Mpf3OTjgO3CM+hkKGaNsbrATALzLCKfUD9q5hZg7bLdX6hHt/kN6aSa/qFwkMzRnWcX+hLbCAGpegMDIkFTcp6ZM2m";

        private ApiContext apiCtx;

        private GetOrdersCall getOrdersCall;
        
        public EbayApiMgr()
        {

        }

        public void Init()
        {
            SetupApiContext();
        }

        private void SetupApiContext()
        {
            apiCtx = new ApiContext();

            apiCtx.SoapApiServerUrl = ApiServerUrl;
            apiCtx.Site = SiteCodeType.US;

            ApiCredential creds = new ApiCredential();
            creds.eBayToken = UserAuthTokenTemp; // [!] Get it from config
            apiCtx.ApiCredential = creds;
        }

        private void SetupGetOrdersCallCommon(ref GetOrdersCall getOrdersCall)
        {
            getOrdersCall.OrderRole = TradingRoleCodeType.Seller;
            getOrdersCall.OrderStatus = OrderStatusCodeType.Completed;
            getOrdersCall.SortingOrder = SortOrderCodeType.Descending;
        }

        public List<OrderType> GetOrders(DateTime createTimeFrom, DateTime createTimeTo, ResultSortOrder resultSetSortOrder)
        {
            getOrdersCall = new GetOrdersCall(apiCtx);
            SetupGetOrdersCallCommon(ref getOrdersCall);

            getOrdersCall.CreateTimeFrom = createTimeFrom;
            getOrdersCall.CreateTimeTo = createTimeTo;
            getOrdersCall.Pagination = new PaginationType();

            var resultList = new List<OrderType>();
            int currentPageNumber = 0;
            int totalPagesNumber = 1; // Default
            
            while (true)
            {
                currentPageNumber++;

                getOrdersCall.Pagination.PageNumber = currentPageNumber;

                getOrdersCall.Execute();

                if (currentPageNumber == 1 && getOrdersCall.OrderList.Count <= 0)
                    return null;

                // Collect the data
                foreach (OrderType orderInfo in getOrdersCall.OrderList)
                {
                    resultList.Add(orderInfo);
                }

                if (currentPageNumber == 1 && getOrdersCall.PaginationResult.TotalNumberOfPages > 1)
                {
                    totalPagesNumber = getOrdersCall.PaginationResult.TotalNumberOfPages;
                }

                if (currentPageNumber == totalPagesNumber)
                    break;
            }

            resultList = resultSetSortOrder == ResultSortOrder.Descending ? 
                resultList.OrderByDescending(x => x.CreatedTime).ToList() :
                resultList.OrderBy(x => x.CreatedTime).ToList();

            return resultList;
        }
    }
}
